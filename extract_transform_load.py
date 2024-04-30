import pandas as pd
import pymysql
import glob

# Execute SQL command
def execute_command(connection, command, value=None):
    cursor = connection.dbcursor
    try:
        if command.strip() != '':
            if value is not None:
                cursor.execute(command, value)
            else:
                cursor.execute(command)

    except pymysql.Error as err:
        pass

#  Get value from row
def get_value(row, key, default):
    return row.get(key) if pd.notnull(row.get(key)) else default

# Load data to database
def load_data_to_db(db, results):
    print("Loading data to database ...")
    for index, row in results.iterrows():
        # Insert distinct industry code and description
        industry_query = """
        INSERT INTO IndustryCode (industry_code, industry_description)
        VALUES (%s, %s)
        """
        industry_values = [get_value(row, 'industry_code', "00"), get_value(row, 'industry_description', "Unknown")]
        execute_command(db, industry_query, industry_values)

        # Insert distinct employer information
        employer_query = """
        INSERT INTO Employer (employer_name, employer_tax_id, employer_city, employer_state, employer_zip_code, employer_industry_code)
        VALUES (%s, %s, %s, %s, %s, %s)
        """
        employer_values = [get_value(row, key, default) for key, default in zip(['Employer (Petitioner) Name', 'Tax ID', 'Petitioner City', 'Petitioner State', 'Petitioner Zip Code', 'industry_code'], ["Unknown", "0000", "Unknown", "XX", "00000", "00"])]
        execute_command(db, employer_query, employer_values)
            
    
        # Insert result data with foreign key reference to industry code and employer
        employer_id_query = "SELECT employer_id FROM Employer WHERE employer_name = %s AND employer_tax_id = %s AND employer_city = %s AND employer_state = %s AND employer_zip_code = %s"
        employer_id_values = employer_values[:5]
        db.dbcursor.execute(employer_id_query, employer_id_values)
        employer_id_fetch = db.dbcursor.fetchone()
        if employer_id_fetch is not None:
            employer_id = employer_id_fetch[0]
        else:
            print(index, "Employer ID not found")
            break
        result_query = """
        INSERT INTO Result (fiscal_year, employer_id, registrations, approval_status, initial_round) 
        VALUES (%s, %s, %s, %s, %s)
        """
        result_values = [row.get(key) for key in ['fiscal_year', 'registrations', 'approve_status', 'initial_round']]
        result_values.insert(1, employer_id)
        result_values = [None if pd.isnull(value) else value for value in result_values]
        execute_command(db, result_query, result_values)

    db.commit_db()
    print("Data is loaded succesfully to database.")

# Transform data
def transform_data(data):
    print("Transforming data ...")
    data = (
        data.rename(columns={'Fiscal Year   ': 'fiscal_year'})
        .melt(
            id_vars=['fiscal_year', 'Employer (Petitioner) Name', 'Tax ID', 'Industry (NAICS) Code', 'Petitioner City', 'Petitioner State', 'Petitioner Zip Code'],
            value_vars=['Initial Approval', 'Initial Denial', 'Continuing Approval', 'Continuing Denial'],
            var_name='status',
            value_name='registrations'
        )
        .assign(
            approve_status=lambda df: df['status'].str.contains('Approval'),
            initial_round=lambda df: df['status'].str.contains('Initial'),
            industry_code=lambda df: df['Industry (NAICS) Code'].str.split(' - ', expand=True)[0],
            industry_description=lambda df: df['Industry (NAICS) Code'].str.split(' - ', expand=True)[1]
        )
    )
    data['registrations'] = data['registrations'].str.replace(',', '').fillna(0).astype(int)
    return data

# Extract data from source
def extract_data():
    print("Extracting data from source ...")
    file_paths = glob.glob("data_source/*.csv")
    data_list = [pd.read_csv(file, encoding='utf-8', delimiter='\t')for file in file_paths]
    data = pd.concat(data_list)
    return data

# Establish the database connection
def create_database(db):
    print("Creating database ...")
    command_types = {
        'DROP DATABASE': [],
        'CREATE DATABASE': [],
        'USE': [],
        'DROP TABLE': [],
        'CREATE TABLE': []
    }

    # Store the SQL commands in a list
    with open('create-db.sql', 'r') as file:
        sql = file.read()
        commands = sql.split(';')
        for command in commands:
            for command_type in command_types:
                if command_type in command:
                    command_types[command_type].append(command)

    # Execute each command
    for command_type, command_list in command_types.items():
        for command in command_list:
            execute_command(db, command)

    print("Database is created successfully.")

# Extract, transform, and load data
def extract_transform_load(db):
    create_database(db)
    extracted_data = extract_data()
    transformed_data = transform_data(extracted_data)
    load_data_to_db(db, transformed_data)