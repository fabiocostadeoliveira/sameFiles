class ClientConfiguration:
    def __init__(self):
        self.client_name = ""
        self.db_directory = ""
        self.db_port = ""
        self.work_directory = ""
        self.user = ""
        self.password = ""
        self.dlc_path = ""
        self.propath = list()

    def add_propath(self, path):
        self.propath.append(path)

    def set_propath_with_semicolon(self, complete_path: str):
        paths = complete_path.split(',')
        for p in paths:
            self.add_propath(p)

    def __str__(self):
        return self.client_name

