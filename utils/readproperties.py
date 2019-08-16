import configparser as cfgparse
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


print(list(get_properties_files('./properties')))

