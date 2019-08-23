import configparser as cfgparse
import os
import json
import sys
import settings
from utils.oscommands import get_files_by_directory as GetFiles;


def get_properties_files(directory):
    files = GetFiles(directory)
    files = filter(lambda f: f.endswith('properties'), files)
    return files


def read_properties_without_section(cfgfile):
    try:
        with open(cfgfile, 'r') as f:
            config_string = '[DEFAULT]\n' + f.read()
        cfg = cfgparse.ConfigParser()
        cfg.read_string(config_string)
    except FileNotFoundError:
        print('Arquivo de configuracao nao existe: ' + cfgfile)
    except cfgparse.MissingSectionHeaderError:
        print('Arquivo sem section')
    return cfg


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

##print(list(get_properties_files('./properties')))

