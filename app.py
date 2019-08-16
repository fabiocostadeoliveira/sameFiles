import configparser as cfgparse

import os
import utils.readproperties as rp
import entities.clientconfig
from utils.oscommands import getMd5
from utils.oscommands import get_files_by_directory

from utils.oscommands import put_os_separator_in_path
from entities.clientconfig import ClientConfiguration
from types import SimpleNamespace


def create_dict_cfg(cfgdirectory: str, cfgfiles: list):
    all_config = dict()
    for filecfg in cfgfiles:
        cfg = rp.read_properties_without_section(cfgdirectory + os.sep + filecfg)
        odict = cfg.defaults()
        db_name = odict.get('nomebase')
        all_config[db_name] = dict(odict.items())
    return all_config


def new_clientconfig_by_dict_properties(client_cfg: dict):
    cli = ClientConfiguration()
    cli.client_name = client_cfg.get()


if __name__ == '__main__':
    directory = 'properties'
    cfgFiles = get_files_by_directory(directory)
    database_cfgs = create_dict_cfg(directory, cfgFiles)
    print(database_cfgs)

    # a = SimpleNamespace(**database_cfgs)
    # print(type(database_cfgs['agriter']['porta']))
    # b = SimpleNamespace(**a.agriter)
    # print(b.porta)
    #
    # porta = a.agriter.get('portaa', None) or 1
    # print(porta)




