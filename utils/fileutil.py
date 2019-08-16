import os


def extract_filename_from_fullname(fullname: str):
    pos_sep = fullname.rfind(os.sep)
    file_name = fullname
    if pos_sep > 0:
        file_name = fullname[pos_sep + 1:]
    return file_name


def extract_path_from_fullname(fullname: str):
    pos_sep = fullname.rfind(os.sep)
    path = fullname
    if pos_sep > 0:
        path = fullname[: pos_sep]
    return path
