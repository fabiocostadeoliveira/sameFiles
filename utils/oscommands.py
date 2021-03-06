import hashlib, os;
from os import listdir
from os.path import isfile, join
from utils.fileutil import extract_filename_from_fullname


def get_md5_file(fileName, dirName=None):
    fileAbsoluteAux = ''
    if dirName is None:
        fileAbsoluteAux = fileName
    else:
        fileAbsoluteAux = dirName + os.sep + fileName
    try:
        hasher = hashlib.md5()
        with open(fileAbsoluteAux, 'rb') as afile:
            buf = afile.read()
            hasher.update(buf)
            afile.close()
        return hasher.hexdigest()
    except IOError:
        print('Erro ao tentar ler o arquivo: ', fileAbsoluteAux)
        return None
    return None


def get_md5_string(text: str):
    try:
        if text is '':
            raise  ValueError('Nao é possivel gerar md5 de uma string vazia!!!')
        hasher = hashlib.md5()
        buf = text.encode()
        hasher.update(buf)
        return hasher.hexdigest()

    except ValueError as verror:
        print(verror)

    return None


def getMd5_2(fileName, dirName=None):
    if dirName is None:
        fileAbsoluteAux = fileName
    else:
        fileAbsoluteAux = dirName + os.sep + fileName
    try:
        hasher = hashlib.md5()
        with open(fileAbsoluteAux, 'rb') as afile:
            for chunk in iter(lambda: afile.read(4096), b""):
                hasher.update(chunk)
        return hasher.hexdigest()
    except IOError:
        print('Erro ao tentar ler o arquivo: ', fileAbsoluteAux)
        return None
    return None


def filter_contains_insensitive(str_filter: str, list_files: list):
    return list(filter(lambda f: str_filter.lower() in f.lower(), list_files))


def filter_contains(str_filter: str, list_files: list):
    return list(filter(lambda f: str_filter in f, list_files))


def filter_with_asterisk(file: str, filter):

    if len(filter) == 1 and filter == '*':
        return True
    if filter[:1] == '*':
        return file.endswith(filter[1:])
    if filter[-1:] == '*':
        return file.startswith(filter[0:-1])
    if file == filter:
        return True

    return False


def rule_list_file(full_file_name: str, contains):
    only_file_name = extract_filename_from_fullname(full_file_name)

    if isfile(full_file_name) is False:
        return False

    f_contains = None
    if type(contains) == list:
        for c in contains:
            f_contains = filter_with_asterisk(only_file_name, c)
            if f_contains is True:
                break
    else:
        f_contains = filter_with_asterisk(only_file_name, contains)

    return f_contains


def get_files_by_directory(directory, contains='*', contains_insensitive=None, only_files=True, recusive=False):
    files = list()
    if contains is not None and type(contains) == list:
        for f in contains:
            if isfile(join(directory, f)):
                files.append(f)
            else:
                print('Warning: Fonte {0} nao existe no diretorio {1}'.format(f, directory))
    else:
        files = [f for f in listdir(directory) if rule_list_file(join(directory, f), contains)]
    return files


def put_os_separator_in_path(directory):
    if directory[-1] != os.sep:
        directory += os.sep
    return directory
