# Calendar
A T-SQL  Stored Procedure to generate a Date Table. Just input a year and a week start date, it will show that year's calendar with workdays flag, week information and Ontario's Public Holidays.

### select * from @ontarioholiday
![image](https://user-images.githubusercontent.com/53555169/125895099-9bfa8537-78b8-4bb2-a262-94a1a4dc0d02.png)


### Step 1. exec usp_CreateDimDate @year=2021    
### Step 2. select * from DimDate
![image](https://user-images.githubusercontent.com/53555169/125895050-02f5dbd6-d486-40ce-b301-fd7868de4961.png)
