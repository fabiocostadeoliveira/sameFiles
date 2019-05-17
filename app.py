import hashlib, os
from os import listdir
from os.path import isfile,join


def getMd5(fileName, dirName=None):
    fileAbsoluteAux = ''
    if dirName is None:
        fileAbsoluteAux = fileName
    else:
        fileAbsoluteAux = dirName + os.sep + fileName
        print(fileAbsoluteAux)
    try:
        hasher = hashlib.md5()
        with open(fileAbsoluteAux, 'rb') as afile:
            buf = afile.read()
            hasher.update(buf)
        return hasher.hexdigest()
    except IOError:
        print('Erro ao tentar ler o arquivo: ', fileAbsoluteAux)
        return None
    return None


def getFilesByDirecory(dir):
    files = [f for f in listdir(dir) if isfile(join(dir, f))]
    return files

def putOsSeparatorInPath(dir):
    if dir[len(dir) - 1:] != os.sep:
        dir + os.sep
    return dir

print(getMd5('c:\\choose.i'))
print(getMd5('choose.i', dirName='c:'))

files = getFilesByDirecory('c:\\')

print(files)

print(putOsSeparatorInPath("c:"))
