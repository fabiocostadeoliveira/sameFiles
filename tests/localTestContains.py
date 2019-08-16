# texto = '.p'
# arqs = ['est118ad.p', 'est502.p', 'fin207.p', 'fin130.p', 'est118ag.p']
# arqsFilter = list(filter(lambda f: texto in f, arqs))
# print(str(arqsFilter))



#file = '/usr/pro/p/desenv/est118ad.p'
# file = 'c:\\fabio\\projetos\\est118ad.p'
#
# print('aqui',file,file.count("\\"))
# pos_sep = file.rfind('\\')
# if pos_sep > 0:
#     print(file[pos_sep + 1:])

# from utils.fileutil import extract_filename_from_fullname
# from utils.fileutil import extract_path_from_fullname
# print(extract_filename_from_fullname('c:\\fabio\\est118ad.p'))
#
# print(extract_path_from_fullname('c:\\fabio\\est118ad.p'))

# from entities.myfile import MyFile
# f = MyFile('c:\\saaaa\\est118ad.p')
# print('uso:',f.name,':', f.fullname,': path: ', f.path)

from os import listdir
from os.path import isfile, isdir, join


def get_type_file(file_name: str):
    ##print('file_name', file_name)
    if isfile(file_name):
        return "file"
    elif isdir(file_name):
        return "directory"
    else:
        return "undefined"


def filter_name(file_name: str, contains=None, contains_case_insensitive=False):
    if contains is None:
        return True
    if contains_case_insensitive:
        file_name = file_name.lower()
        contains = contains.lower()
    if contains in file_name:
        return True
    else:
        return False


# dir_cliente = "C:\\Cooperate\\"
#
#
# files = {join(dir_cliente, f): get_type_file(join(dir_cliente, f)) for f in listdir(dir_cliente) if filter_name(f,contains=".UP",contains_case_insensitive=True) is True}
#
# print(files)

lista_varrer = ['fabio','costa','de','oliveira']
a = [('nome','fabio'),('nome','jose'),('nome','maria'),('fonte',{'md5':'aaaaaaaa'})]
lista = []
obj = {}

for n in lista_varrer:
    obj = {n:{"md5": n + str(1)} }
    lista.append(obj)

for k, v in a:
    print('k', k, 'v', v)

print(lista)



