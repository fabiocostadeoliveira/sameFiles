import os
from utils.oscommands import get_md5_file as Md5
from utils.fileutil import extract_filename_from_fullname
from utils.oscommands import put_os_separator_in_path
from entities.myfile import MyFile


def search_same_file_in_directories(file: str, directories: list, recursive=None):
    md5_origin = Md5(file)
    file_origin = MyFile(file)

    for dir in directories:
        file_aux = put_os_separator_in_path(dir) + file_origin.name
        exists = os.path.isfile(file_aux)
        if exists:
            break
    if exists:
        md5 = Md5(file_aux)






