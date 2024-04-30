from extract_transform_load import *
from connectdb import DBconnect
from tabulate import tabulate

def execute_insights(db, command):
    try:
        if command.strip():
            db.dbcursor.execute(command)
            results = db.dbcursor.fetchall()
            columns = db.dbcursor.description

            if columns:
                headers = [column[0] for column in columns]
                results = [dict(zip(headers, row)) for row in results]

            print('\n' + tabulate(results, headers="keys", tablefmt='psql') + '\n')
    except pymysql.Error as err:
        print(f"Failed executing command: {command}\n{err}")

def insights(db):
    with open('insights.sql', 'r') as file:
        command_list = {}
        sql = file.read()
        commands = sql.split(';')
        commands.pop()
        commands = [command.split('\n\n') for command in commands]
        commands = [command[1:] for command in commands]
        for i in range(len(commands)):
            command_list[commands[i][0].split(":")[0][-2:].strip()] = {'name': commands[i][0].split(":")[1].strip(),
                                                                       'command': commands[i][1].strip()}
    
    while True:
        print('\n' + '*' * 170)
        for key, value in command_list.items():
            print(f'* Enter {key} to view {value["name"].ljust(151 if len(str(key)) == 1 else 150)}*')
        print('* Enter x to exit' + ' ' * 152 + '*\n' + '*' * 170)

        while True:
            try:
                selection = input('\nMake your selection: ')
                if selection not in list(command_list.keys()) + ['x']:
                    raise Exception
                break
            except Exception:
                print(f'\nSelection should be 1, 2, 3, ..., {len(command_list)}. Try again .....')

        if selection == "x":
            print("\nThank you for visiting NonImmigrant Visa Lottery Database System. Come back soon.\n")
            exit()
        else:
            execute_insights(db, command_list[selection]['command'])
            selection = input('Do you want to continue? (y/n): ')
            if selection.lower() == 'n':
                print("\nThank you for visiting NonImmigrant Visa Lottery Database System. Come back soon.\n")
                exit()

def menu(db):
    print('\n' + '*' * 170)
    print('*' + ' ' * 58 + 'Welcome to NonImmigrant Visa Lottery Database System'+ ' ' * 58 + '*')
    print('*' + ' ' * 168 + '*')
    print('* Enter 1 to explore the lottery insights' + ' ' * 128 + '*')
    print('* Enter 2 to exit' + ' ' * 152 + '*\n' + '*' * 170)

    while True:
        try:
            selection = int(input('\nMake your selection: '))
            if selection not in range(1, 3):
                raise Exception
            break
        except Exception:
            print('Selection should be 1, or 2.  Try again .....')

    if selection == 2:
        print("\nThank you for visiting NonImmigrant Visa Lottery Database System. Come back soon.\n")
        exit()

    if selection == 1:
        insights(db)

def main():
    db = DBconnect()
    extract_transform_load(db)
    menu(db)

if __name__ == "__main__":
    main()