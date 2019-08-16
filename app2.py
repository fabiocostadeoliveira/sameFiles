import properties.cfggeral as cfg
import getopt, sys
from shutil import copy2 as os_copy
from utils.oscommands import getMd5, getMd5_2
from utils.oscommands import get_files_by_directory
import hashlib, os
from os.path import isfile, join
from datetime import datetime


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


def cli(argv):
    try:
        opts, args = getopt.getopt(argv, "hvda:b:c:", ["dbmain=", "dbcliente=", "--files=", "cp"])
    except getopt.GetoptError:
        print('exec.py --dbmain=nome_dump1 --dbcliente=nome_dump2')
        sys.exit(2)
    opcoes = dict()

    for opt, arg in opts:
        if opt == '-h':
            print('--dbmain [opcional, default main]', '--dbcliente', '--cp[efetua a copia]')
            sys.exit()
        elif opt == '-v':
            sys.exit()
        elif opt in ("-a", "--dbmain"):
            opcoes['dbmain'] = arg
        elif opt in ("-b", "--dbcliente"):
            opcoes['dbcliente'] = arg
        elif opt in ("-c", "--cp"):
            opcoes['cp'] = True

    if opcoes.get('dbmain', None) is None:
        opcoes['dbmain'] = 'main'

    if opcoes.get('cp', None) is None:
        opcoes['cp'] = False

    if opcoes.get('dbcliente',None) is None:
        print("Parametros Invalidos!!!")
        print("Devem ser informados pelo menos o parametro --dbcliente para a comparacao")
        exit(1)
    return opcoes


if __name__ == '__main__':
    opcoes = cli(sys.argv[1:])

    print('opcoes', opcoes)
    fazer_copia_fontes = opcoes['cp']
    db_main = opcoes['dbmain']
    db_cliente = opcoes['dbcliente']

    # fontes = ['nfe*', 'bib*', 'epc*', 'efd*', 'epj*']
    fontes = ['nfe002wr.trg', 'ecd501.p','usu201d.p','cadp708.p']

    if cfg.clientes.get(db_main, None) is None:
        print('Configuracao para base main "{0}" nao encontrada'.format(db_main))
        sys.exit(1)

    if cfg.clientes.get(db_cliente, None) is None:
        print('Configuracao para base cliente "{0}" nao encontrada'.format(db_cliente))
        sys.exit(1)

    dir_main = cfg.clientes[db_main]['propath'][0]
    diretorios_cliente = cfg.clientes[db_cliente]['propath']

    diretorio_destino_copia = 'C:\\testeMd5\\cliente1\\cooperate\\atu'

    print_custom('Carregando lista de fontes...')
    fontes_main = get_files_by_directory(dir_main, contains=fontes)

    print_custom('Obtendo Md5 arquivos do main...')
    fontes_main_com_md5 = dict()
    for f in fontes_main:
        fontes_main_com_md5[f] = {'md5': getMd5(f, dir_main)}

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
                md5_cliente = getMd5(nome_completo)
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

        # colocar for dos diretorios
        #print('fonte', key, 'md5 cli:', md5_cli, 'md5 main: ', md5_main)
        if md5_cli is '':
            fontes_status[key] = {'status': 'novo'}
        elif md5_cli != md5_main:
            fontes_status[key] = {'status': 'diferente'}
        elif md5_cli == md5_main:
            fontes_status[key] = {'status': 'igual'}
        else:
            fontes_status[key] = {'status': 'indefinido'}

    print('destino', diretorio_destino_copia)
    for idx, obj in fontes_status.items():
        if obj['status'] is not 'igual':
            arquivo = join(dir_main, idx)
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

    print('Copia concluida')