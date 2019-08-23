import unittest, platform, os, tests.test_contants as const
from utils.oscommands import get_md5_file as Md5;
from utils.oscommands import put_os_separator_in_path as Ps
from utils.oscommands import get_files_by_directory as GetFiles


class TestOsCommands(unittest.TestCase):

    def test_getMd5File(self):
        self.assertEqual(Md5(const.FILE_TESTE_1), '7c445967ecf71886c1ae5188ec2318d6')

    def test_putOsSeparatorInPath(self):
        fileAux = ['project', os.sep, 'tests']
        self.assertEqual(Ps(''.join(fileAux)), ''.join(fileAux) + os.sep)

    def test_getFilesByDirecory(self):
        files: list = GetFiles('.', contains='file')
        self.assertEqual(const.FILE_TESTE_1 in files, True)


if __name__ == '__main__':
    unittest.main()
