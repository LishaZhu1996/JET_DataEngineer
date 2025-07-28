#Part1 Extract and load the data
# import the package which is needed in our script
import requests
import json
import pyodbc
import pandas as pd
import logging

Id = "Id passed from the pipeline"
database_server_name = "Example database severname"
database_name = "Example database name"
username = "Example username to database"
password = "Example PW to database"

# Connect to database to get the API endpoint and current num loaded
conn = pyodbc.connect(
        'Driver={ODBC Driver 17 for SQL Server};'
        f'Server={database_server_name};'
        f'Database={database_name};'
        f'UID={username};'
        f'PWD={password};'
        'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=60;'
    )
cursor = conn.cursor()
cursor.execute(f"SELECT BasicEndpointurl,Num_Max_DB,Fullload FROM tmp.EntityControlTable WHERE id = {Id}")
row = cursor.fetchone()
if row:
    endpoint = row.BasicEndpointurl
    maxnum_db = row.Num_Max_DB
    fullload = row.Fullload
conn.close()

#Get the current num from API
maxnum_api = requests.get(endpoint).json()['num']

#Define a function, based on API. current number loaded in database and loading mode to achive different loading purpose
def loading_entity(endpoint,maxnum_db,fullload):
    if (fullload == 1) or (fullload == 0 and maxnum_db is None):
    #if it is a fullload or although it defines as delta load, the maxnum_db loaded in database is null, then we will load all of the records
        api_list = [endpoint.replace('/info', f'/{num}/info') for num in range(1, maxnum_api + 1)]
    elif maxnum_db < maxnum_api:
    # if the num in database is smaller than the max num we got from api and we defined a delta load, then we only load the new records from API
        api_list = [endpoint.replace('/info', f'/{num}/info') for num in range(maxnum_db + 1, maxnum_api + 1)]
    else:
    # if the num in db is equal to the num from current API, then we dont need to do anything
        api_list = None
    return api_list

#Get api_list based on the situation provided 
api_list = loading_entity(endpoint,maxnum_db,fullload) #num = 404 have an error

if api_list is not None:
    data = []
    for url in api_list:
        try :
            response = requests.get(url)
            response.raise_for_status()  # raise an error for bad status codes
            comic_json = response.json()
            data.append(comic_json)
        except Exception as e:
            print(f"Error fetching {url}: {e}")
    # put values in a dataframe
    df = pd.DataFrame(data)

# Save the data locally    
#df.to_csv('C:/Users/LZhu/OneDrive - ACT Commodities/Desktop/Personal/LishaZhu_DataEngineer/ComicFromAPI.csv', index=False)

#The data is getten from the api, now connect to db again and insert the records in the db
conn = pyodbc.connect(
        'Driver={ODBC Driver 17 for SQL Server};'
        f'Server={database_server_name};'
        f'Database={database_name};'
        f'UID={username};'
        f'PWD={password};'
        'Encrypt=yes;TrustServerCertificate=no;Connection Timeout=60;'
    )
cursor = conn.cursor()

# In order to improve the performance of the activity, we devide the whole df into chunks
# Can also help with debug when the first time you try to insert data in the database
# Here I define the chunk size as 1000, it can be chagned
chunk_size = 1000
total_chunks = len(df) // chunk_size + (1 if len(df) % chunk_size != 0 else 0)
# Iterate over the DataFrame in chunks
for i in range(total_chunks):
    start_idx = i * chunk_size
    end_idx = (i + 1) * chunk_size
    chunk_df = df.iloc[start_idx:end_idx]
    table_name = "tmp.ComicsBasic"
    cols = ','.join([str(i) for i in chunk_df.columns.tolist()])
    values = chunk_df.values.tolist()
    qm = ','.join(['?' for i in range(len(chunk_df.columns))])
    sql = f"INSERT INTO {table_name} ({cols}) VALUES ({qm})"
    cursor.fast_executemany = True
    cursor.executemany(sql, values)
    conn.commit()
    logging.info(f"{start_idx} to {end_idx} of the dataframe have been inserted")
conn.close()












