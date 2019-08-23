import getopt
import sys
import os
import json
import settings
from shutil import copy2 as os_copy
from utils.oscommands import get_md5_file, get_md5_string
from utils.oscommands import get_files_by_directory
from os.path import isfile, join
from datetime import datetime


def read_db_config_json():
    try:
        with open(settings.DIRECTORY_CONFIG + os.sep + 'database_config.json', 'r') as f:
            json_config = json.load(f)
        if json_config is not None:
            json_config_dict = dict(json_config)
    except FileNotFoundError as ferror:
        print('Arquivo de configuracao nao encontrado! \n Pilha: {0}'.format(ferror))
    except json.decoder.JSONDecodeError as jsonError:
        print('Erro ao tentar converter json')
    finally:
        if 'json_config_dict' not in locals():
            sys.exit(1)

    return json_config_dict


def hash_bytestr_iter(bytesiter, hasher, ashexstr=False):
    for block in bytesiter:
        hasher.update(block)
    return hasher.hexdigest() if ashexstr else hasher.digest()


def file_as_blockiter(afile, blocksize=65536):
    with afile:
        block = afile.read(blocksize)
        while len(block) > 0:
            yield block
            block = afile.read(blocksize)


def get_data_hora_texto():
    data_e_hora_atuais = datetime.now()
    data_e_hora_em_texto = data_e_hora_atuais.strftime("%d/%m/%Y %H:%M:%S")
    return data_e_hora_em_texto


def print_custom(msg):
    print(get_data_hora_texto(), ' - ', msg)


def get_directory_temp_name(txt: str):
    return get_md5_string(txt)


def create_dir_tmp(text: str):
    md5_name = get_md5_string(text)
    dir_name = settings.DIRECTORY_TEMP_APP + os.sep + md5_name

    try:
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)
    except PermissionError as perror:
        print('Diretorio sem permissao para criar diretorio')
        print(perror)
        return False
    except Exception as e:
        print('Erro ao criar diretorio: ' + text)
        print(e)
        return False
    return dir_name


def cli(argv):
    try:
        opts, args = getopt.getopt(argv, "hvda:b:c:d", ["dbmain=", "dbcliente=", "tagmain=", "dir="])
    except getopt.GetoptError:
        print('exec.py --dbmain=nome_dump1 --dbcliente=nome_dump2 ')
        sys.exit(2)
    opcoes = dict()

    for opt, arg in opts:
        if opt == '-h':
            print('--dbmain [opcional, default main]', '--dbcliente', '--dir[efetua a copia para esse diretorio]')
            sys.exit()
        elif opt == '-v':
            opcoes['v'] = True
        elif opt in ("-a", "--dbmain"):
            opcoes['dbmain'] = arg
        elif opt in ("-b", "--dbcliente"):
            opcoes['dbcliente'] = arg
        elif opt in ("-c", "--tagmain"):
            opcoes['tagmain'] = arg
        elif opt in ("-d", "--dir"):
            opcoes['dir'] = arg

    if opcoes.get('dbmain', None) is None:
        opcoes['dbmain'] = 'main'

    if opcoes.get('v', None) is None:
        opcoes['v'] = False

    if opcoes.get('cache', None) is None:
        opcoes['cache'] = False

    if opcoes.get('dbcliente', None) is None:
        print("O parametro --dbcliente nao foi informado.")
        exit(1)

    if opcoes.get('tagmain', None) is None:
        print("O parametro --tagmain nao foi informado.")
        exit(1)

    return opcoes


def load_tag_version(p_tag_name):
    try:
        with open(p_tag_name, 'r') as file:
            dict_sources = json.load(file)
    except FileNotFoundError as ferror:
        print(f'Arquivo nao encontrado: {p_tag_name}')
        return None
    except Exception as error:
        print(f'Erro ao ler arquivo de tag: {p_tag_name}')
        return None
    return dict_sources


if __name__ == '__main__':
    opcoes = cli(sys.argv[1:])

    cfg = read_db_config_json().get(settings.ENVIRONMENT_DATABASE_CONFIG, None)

    if cfg is None:
        print('Nao foi possivel carregar o ambiente configurado')
        print(f'Ambiente: {settings.ENVIRONMENT_DATABASE_CONFIG}')
        sys.exit(1)

    db_main = opcoes.get('dbmain')
    db_cliente = opcoes.get('dbcliente')
    verbose = opcoes.get('v')
    fazer_copia_fontes = False

    if opcoes.get('dir', None) is not None:
        diretorio_destino_copia = opcoes['dir']
        fazer_copia_fontes = True

    fontes = ['nfe002wr.trg', 'ecd501.p', 'usu201d.p', 'cadp708.p', 'aaaaaaa', 'bbbbbb']
    #fontes = '*'

    if cfg.get(db_main, None) is None:
        print('Configuracao para base main "{0}" nao encontrada'.format(db_main))
        sys.exit(1)

    if cfg.get(db_cliente, None) is None:
        print('Configuracao para base cliente "{0}" nao encontrada'.format(db_cliente))
        sys.exit(1)

    diretorios_main = cfg[db_main]['source_paths'][0]
    diretorios_cliente = cfg[db_cliente]['source_paths']

    print_custom('Carregando lista de fontes do banco {0} ....'.format(db_main))
    fontes_main = get_files_by_directory(diretorios_main, contains=fontes)

    print_custom('Obtendo Md5 arquivos do banco {0}...'.format(db_main))
    fontes_main_com_md5 = dict()

    for f in fontes_main:
        fontes_main_com_md5[f] = {'md5': get_md5_file(f, diretorios_main)}

    print_custom('Fim processo Md5 do main.')

    # Busca fontes na base do cliente
    print_custom('Obtendo fontes do cliente com Md5...')
    list_fontes_cliente = list()
    teste_dict = dict()

    for fonte in fontes_main_com_md5:
        obj = None

        for dir_cliente in diretorios_cliente:
            nome_completo = join(dir_cliente, fonte)

            if isfile(nome_completo):
                md5_cliente = get_md5_file(nome_completo)
                teste_dict[fonte] = {'md5': md5_cliente}
                obj = {fonte: {'md5': md5_cliente}}
                break

        if obj is None:
            teste_dict[fonte] = {'md5': ''}
            obj = {fonte: {'md5': ''}}

        list_fontes_cliente.append(obj)

    print_custom('Compara fontes...')

    fontes_status = dict()

    for key in teste_dict:
        md5_cli = teste_dict[key]['md5']
        md5_main = fontes_main_com_md5[key]['md5']

        if md5_cli is '':
            fontes_status[key] = {'status': 'novo'}
        elif md5_cli != md5_main:
            fontes_status[key] = {'status': 'diferente'}
        elif md5_cli == md5_main:
            fontes_status[key] = {'status': 'igual'}
        else:
            fontes_status[key] = {'status': 'indefinido'}

    for idx, obj in fontes_status.items():

        arquivo = join(diretorios_main, idx)
        if fazer_copia_fontes is False:
            print(arquivo, '.'*20, obj['status'])
        else:
            if obj['status'] is not 'igual':
                print(arquivo, ' para =>', diretorio_destino_copia)
                try:
                    os_copy(arquivo, diretorio_destino_copia)
                except PermissionError as perror:
                    print(perror)
                    print('Sem permissao para copiar os arquivos!!!')
                    exit(1)
                except FileNotFoundError as ferror:
                    print(ferror)
                    print('Arquivo de origem nao encontrado:', arquivo)
                    exit(1)

    print('Finalizado com Sucesso!!')