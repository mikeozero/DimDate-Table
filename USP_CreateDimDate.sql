-- purpose: automaticly calculate Ontario's public holidays of given year, and generate time table: DimDate
-- create date: 2021-07-12 Mike Yu

-- use XXX  -- change to desired datebase
-- go
drop proc if exists usp_CreateDimDate
go
-- parameter: @year -- generate the given year datetable
-- parameter: @weekstartday -- week start from 1: Monday 2: Tuesday ... 0: Sunday; default from Monday
create proc usp_CreateDimDate(@year int,@weekstartday int=1) as
begin
drop table if exists DimDate
-- calculate ontario public holidays
declare @cd date,@nd date,@fd date,@gf date,@vd date,@ld date,@tg date,@cm date,@bx date
-- new year, christmax, boxing day
set @nd = str(@year)+'-01-01'
set @cm = str(@year)+'-12-25'
set @bx = str(@year)+'-12-26'
-- canada day
if datepart(dw,str(@year)+'-07-01') != 1
    set @cd = str(@year)+'-07-01'
else
    set @cd = str(@year)+'-07-02'

-- generate @datetable
declare @datetable table(dt date,wd int,wdn varchar(10),workday int,holiday int,holidayname varchar(20),weeknum varchar(20),weekstartdate date,weekenddate date)
declare @ontarioholiday table(dt date,comments varchar(100))
declare @weektable table(weekstartdate date,weekenddate date,weeknum varchar(20))
declare @date date = @nd
declare @n int = datediff(day,@date,dateadd(year,1,@date))
declare @d int = 1
while @d<=@n
begin  
    insert into @datetable(dt,wd,wdn,workday) values(@date,datepart(dw,@date)-1,datename(dw,@date),case when datepart(dw,@date)-1 in (0,6) then 0 else 1 end)
    set @date = dateadd(day,1,@date)
    set @d+=1
end
-- family day
select @fd=dt from 
(select dt,row_number()over(order by dt) rownum from @datetable where wd = 1 and month(dt)=2)a
where rownum=3
-- victoria's day
select @vd=dt from @datetable where wd = 1 and month(dt)=5 and day(dt) between 18 and 24
-- labour day
select @ld=dt from @datetable where wd = 1 and month(dt)=9 and day(dt) between 1 and 7
-- Thanksgiving
select @tg=dt from @datetable where wd = 1 and month(dt)=10 and day(dt) between 8 and 14

-- Good Friday the most hard one:
declare @mindex int = 24, @nindex int = 5 
declare @x int = ((@year%19)*19+@mindex)%30
declare @y int = ((@year%4)*2+(@year%7)*4+6*@x+@nindex)%7
declare @ed date
if @x+@y<10
begin
    set @ed = str(@year)+'-03-'+str(@x+@y+22)
    set @gf = dateadd(day,-2,@ed)
end
else
begin
    if @x+@y-9=26
        set @ed = str(@year)+'-04-19'
    else if @x+@y-9=25 and @x=28 and @y=6 and @year%19>10
        set @ed = str(@year)+'-04-18'
    else
        set @ed = str(@year)+'-04-'+str(@x+@y-9)
    set @gf = dateadd(day,-2,@ed)
end

-- generate ontarioholiday temp table
insert into @ontarioholiday values
(@nd,'New Year'),
(@fd,'Family Day'),
(@gf,'Good Friday'),
(@vd,'Victoria Day'),
(@cd,'Canada Day'),
(@ld,'Labour Day'),
(@tg,'Thanksgiving'),
(@cm,'Christmas'),
(@bx,'Boxing Day')

-- update holiday infomation
update @datetable set holiday=case when o.dt is null then 0 else 1 end,holidayname=o.comments from @datetable d left join @ontarioholiday o on d.dt=o.dt

-- generate weektable temp table, week start date is monday
declare @temptable table(dt date,wd int)
insert into @temptable select dt,wd from @datetable where wd=@weekstartday
declare @mindt date
select @mindt=min(dt) from @temptable
if @mindt!=@nd
    insert into @temptable values(dateadd(day,-7,@mindt),@weekstartday)
insert into @weektable
select dt,dateadd(day,6,dt),'WEEK'+ case when ROW_NUMBER()over(order by dt)<10 then '0'+cast(ROW_NUMBER()over(order by dt) as varchar) else cast(ROW_NUMBER()over(order by dt) as varchar) end from @temptable

-- update week infomation
update @datetable set weeknum=w.weeknum,weekstartdate=w.weekstartdate,weekenddate=w.weekenddate from @datetable d left join @weektable w on d.dt between w.weekstartdate and w.weekenddate
select * from @datetable

-- generate DimDate table
select dt FullDate,wdn WeekdayName,workday WorkdayFlag,holiday HolidayFlag,holidayname HolidayName,weeknum WeekNumber,weekstartdate WeekStartDate,weekenddate WeekEndDate into DimDate from @datetable 
end
go

-- test
-- exec usp_CreateDimDate @year=2020
-- check result
-- select * from DimDate