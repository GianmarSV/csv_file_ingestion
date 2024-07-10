import re
import polars as pl


class FileInput:
    def path(self):
        pass

    def schema(self):
        pass

class JobsFile(FileInput):
    @property
    def path(self):
        return 'jobs'

    @property
    def schema(self):
        return {
            'id': pl.Int16,
            'job': pl.String
        }

class HiredEmployeesFile(FileInput):
    @property
    def path(self):
        return 'hired_employees'
    
    @property
    def schema(self):
        return {
            'id': pl.Int16,
            'name': pl.String,
            'datetime': pl.Datetime,
            'department_id': pl.Int16,
            'job_id': pl.Int16
        }
    
class DepartmentsFile(FileInput):
    @property
    def path(self):
        return 'departments'
    
    @property
    def schema(self):
        return {
            'id': pl.Int16,
            'department': pl.String
        }

class UnknownsFile(FileInput):
    @property
    def path(self):
        return 'unknowns'

class FileClassifier:
    FILE_TYPES = {
        r'^jobs\.csv$': JobsFile,
        r'^hired_employees\.csv$': HiredEmployeesFile,
        r'^departments\.csv$': DepartmentsFile,
    }
    _file_input = None
    path = None

    def __init__(self, filename):
        self.filename = filename
        self.file_input = self.classify()
        self.path = self.file_input.path
        self.schema = self.file_input.schema

    def classify(self):
        for pattern, class_file in self.FILE_TYPES.items():
            if re.match(pattern, self.filename):
                return class_file()
        return UnknownsFile()


#a = FileClassifier('jobs.csv')
#print(a.path)