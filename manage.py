import getopt
import sys
import os
import json
import traceback
import settings as cfg
from utils import oscommands as cmd
from utils.readproperties import read_db_config_json


def cli(argv):
    try:
        opts, args = getopt.getopt(argv, "hvda", ["tagmain="])
    except getopt.GetoptError:
        print('manager.py --tagmain=nome_da-versao')
        sys.exit(2)
    opcoes = dict()

    for opt, arg in opts:
        if opt == '-h':
            print('manager.py --tagmain=nome_da-versao')
            sys.exit()
        elif opt == '-v':
            opcoes['v'] = True
        elif opt in ("-a", "--tagmain"):
            opcoes['tagmain'] = arg

    if opcoes.get('tagmain', None) is None:
        print("Parametros Invalidos!!!")
        print("Devem ser informados o nome da tag --tagmain nome_da_versao")
        exit(1)

    return opcoes


def create_file_tag(p_file_tag_name: str, content: str):
    try:
        file_tag = open(p_file_tag_name, 'w')
        json.dump(content, file_tag, indent=4)
        file_tag.close()
    except PermissionError as permisson_error:
        print(f'Erro de permissao para gravar arquivo {p_file_tag_name}')
        traceback.print_exc()
    except Exception as eror:
        traceback.print_exc()
        print(f'Erro ao gerar tag de versao {p_file_tag_name}')


def tag_main_by_db():
    pass


def tag_main_by_file(p_version: str):

    try:
        if os.path.exists(os.path.exists(cfg.DIRECTORY_TAGS_MAIN)) is False:
            raise FileNotFoundError(f'Diretorio {cfg.DIRECTORY_TAGS_MAIN} nao existe!!')

        file_tag = cfg.DIRECTORY_TAGS_MAIN + os.sep + p_version + '.json'

        if os.path.isfile(file_tag):
            print(f'Tag {p_version} ja existe !!')
            sys.exit(0)

        db_main = read_db_config_json()[cfg.ENVIRONMENT_DATABASE_CONFIG]['main']

        source_path = db_main.get('source_paths')[0]

        if os.path.exists(source_path) is False:
            raise FileNotFoundError(f'Diretorio de fontes nao existe: {source_path}')

        print(f'carregando arquivos do diretorio {source_path}...')

        fontes_main = cmd.get_files_by_directory(source_path)

        fontes_com_md5 = dict()

        print(f'Aguarde, carregando MD5 dos arquivos ....')
        for fonte in fontes_main:
            fontes_com_md5[fonte] = {'md5': cmd.get_md5_file(fonte, source_path)}

        if len(fontes_com_md5) > 0:
            create_file_tag(file_tag, fontes_com_md5)
        print('Pronto')

    except FileNotFoundError as file_not_found_error:
        print(str(file_not_found_error) + '\n Verifique o arquivo settings')
        sys.exit(1)
    except Exception as general_error:
        print('Erro nao catalogado', general_error)
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    options = cli(sys.argv[1:])

    if options.get('tagmain', None) is not None:
        tag_main_by_file(options.get('tagmain'))




