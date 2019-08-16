from utils.fileutil import extract_filename_from_fullname, extract_path_from_fullname
class MyFile:
    def __init__(self, fullname, md5hash=None ,encode=None):
        self.fullname = fullname
        self.md5hash = md5hash
        self.encode = encode

    @property
    def name(self):
        return self.__name

    @name.getter
    def name(self):
        return self.__name

    @property
    def path(self):
        return self.__path

    @property
    def fullname(self):
        return self.__fullname

    @fullname.setter
    def fullname(self, pfullname):
        self.__name = extract_filename_from_fullname(pfullname)
        self.__path = extract_path_from_fullname(pfullname)
        self.__fullname = pfullname
