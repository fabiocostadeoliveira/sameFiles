from entities.myfile import MyFile
import json


from json import JSONEncoder


class MyEncoder(JSONEncoder):
    def default(self, o):
        return o.__dict__


f = MyFile('C:\\temp\\cadp708.p')
print(MyEncoder().encode(f))

print(json.dumps(f, cls=MyEncoder))