-- Create table
create table Bank
(
  id   number(4),
  name varchar2(20),
  code char(2)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table Bank
  add constraint PK_BANK_ID primary key (ID);
alter table BANK
  add constraint PK_BANK_CODE unique (CODE);

-- Create table
create table client
(
  id      number(4),
  name    varchar2(20),
  address varchar2(80),
  tel     varchar2(20)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table client
  add constraint PK_CLIENT_ID primary key (ID);

-- Create table
create table device
(
  deviceid number(4),
  clientid number(4),
  type     char(2),
  balance  number(7,2)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table device
  add constraint PK_DEVICE_DEVICEID primary key (DEVICEID);
alter table device
  add constraint FK_DEVICE_CLIENTID foreign key (CLIENTID)
  references client (ID);

-- Create table
create table electricity
(
  id        number(4),
  deviceid  number(4),
  yearmonth char(6),
  snum      number(10)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table electricity
  add constraint PK_ELECTRICITY_ID primary key (ID);
alter table electricity
  add constraint FK_ELECTRICITY_DEVICEID foreign key (DEVICEID)
  references device (DEVICEID);


-- Create table
create table RECEIVABLES
(
  id        number(4),
  yearmonth char(6),
  deviceid  number(4),
  basicfee  number(7,2),
  flag      char(1)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table RECEIVABLES
  add constraint PK_RECEIVABLES_ID primary key (ID);
alter table RECEIVABLES
  add constraint FK_RECEIVABLES_DEVICEID foreign key (DEVICEID)
  references device (DEVICEID);

-- Create table
create table PAYFEE
(
  id         number(4),
  deviceid   number(4),
  paymoney   varchar2(20),
  paydate    date,
  bankcode   char(2),
  type       char(4),
  bankserial varchar2(20)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table PAYFEE
  add constraint PK_PAYFEE_ID primary key (ID);
alter table PAYFEE
  add constraint FK_PAYFEE_DEVICEID foreign key (DEVICEID)
  references device (DEVICEID);
alter table PAYFEE
  add constraint FK_PAYFEE_BANKCODE foreign key (BANKCODE) 
  references BANK (CODE);

-- Create table
create table BANKRECORD
(
  id         number(4),
  payfee     number(7,2),
  bankcode   char(2),
  bankserial varchar2(20)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table BANKRECORD
  add constraint PK_BANKRECORD_ID primary key (ID);
alter table BANKRECORD
  add constraint FK_BANKRECORD_BANKCODE foreign key (BANKCODE)
  references BANK (CODE);


-- Create table
create table CHECKRESULT
(
  id             number(4),
  checkdate      date,
  bankcode       char(2),
  banktotalcount number(4),
  banktotalmoney number(10,2),
  ourtotalcount  number(4),
  ourtotalmoney  number(10,2)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table cHECKRESULT
  add constraint PK_CHECKRESULT_ID primary key (ID);
alter table CHECKRESULT
  add constraint FK_CHECKRESULT_BANKCODE foreign key (BANKCODE)
  references BANK (CODE);


-- Create table
create table check_exception
(
  id            number(4),
  checkdate     date,
  bankcode      char(2),
  bankserial    varchar2(20),
  bankmoney     number(7,2),
  ourmoney      number(7,2),
  exceptiontype char(3)
)
;
-- Create/Recreate primary, unique and foreign key constraints 
alter table check_exception
  add constraint PK_CHECKEXCEPTION_ID primary key (ID);
alter table CHECK_EXCEPTION
  add constraint FK_CHECKEXCEPTION_BANKCODE foreign key (BANKCODE)
  references BANK (CODE);


2.
select ID
from client join device on  client.id=device.clientid
group by ID
HAVING Count(*)>2;

10.
select  ID
from client join device on  client.id=device.clientid
where deviceid in(select deviceid
from  device  join electricity using(deviceid)
GROUP BY deviceid
HAVING Count(*)<6 
)

8.
select Type,Typenumber
from (select type,Count(*) as Typenumber
      from device
      GROUP by type)
Order BY Typenumber DESC;

6.
select id,UseElectriy
from(
select CurrentMonth.id,CurrentMonth.deviceid,(CurrentMonth.snum-lastMonth.snum) as UseElectriy
from(select client.id,deviceid, snum 
      from client join device on  client.id=device.clientid join electricity using(deviceid)
      where yearmonth='201608' 
      ) lastMonth,
    (select client.id,deviceid, snum 
      from client join device on  client.id=device.clientid join electricity using(deviceid)
      where yearmonth='201609' 
     ) CurrentMonth
where lastMonth.deviceid=CurrentMonth.deviceid
)
where rownum<4
order by UseElectriy;


1.
select ID,NeedPay,really
from(select client.id ,SUM(basicfee)*1.18 AS NeedPay,SUM(paymoney) as really
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)  join payfee using(deviceid)
where device.type='01'
GROUP by client.id
union
select client.id ,SUM(basicfee)*1.23 AS NeedPay,SUM(paymoney) as really
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)  join payfee using(deviceid)
where device.type='02'
GROUP by client.id)
where NeedPay<really

or

select client.name,record
from(select client.id,count(*) as record
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)
where flag='0'
GROUP by client.id) RECORDTABLE ,client
where record>0 and RECORDTABLE.id=client.id;

5.
select ID,(NeedPay-realpay) as shouldpay
from(select client.id ,SUM(basicfee)*1.18 AS NeedPay,SUM(paymoney) as realpay
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)  join payfee using(deviceid)
where device.type='01'
GROUP by client.id
union
select client.id ,SUM(basicfee)*1.23 AS NeedPay,SUM(paymoney) as realpay
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)  join payfee using(deviceid)
where device.type='02'
GROUP by client.id)
where NeedPay>realpay;
3.
select paydate,SUM(paymoney) AS NeedRecive,SUM( payfee ) as actualreceive
from  payfee  join BANKRECORD  using(bankserial)
GROUP BY paydate

4.
select id,deviceid
from(select client.id,deviceid,count(*) as record
from client join device on  client.id=device.clientid  join RECEIVABLES using(deviceid)
where flag='0'
GROUP by client.id,deviceid)
where record>6;

9.
select to_char(paydate,'YYYYMM') as Month,payfee.bankcode,count(*) as record
from  payfee  join BANKRECORD  using(bankserial)
GROUP BY payfee.bankcode,to_char(paydate,'YYYYMM')
order by record;

7.
select day,record
from(
select to_char(paydate,'DD') as day,count(*) as record
from  payfee  join BANKRECORD  using(bankserial)
where to_char(paydate,'YYYYMM')='201608' 
GROUP BY to_char(paydate,'DD')
)
where rownum<2
order by record;

select add_months(to_date(concat(yearmonth,'01'),'YYYYMMDD'),1)
from RECEIVABLES;

 declare
  UserID  client.Id%type;
  querydate   date;
  TotalNeedpay RECEIVABLES.basicfee%type;
  State  int;
begin
  UserID:=2500;
  querydate:=TO_DATE('20161020000000', 'YYYYMMDDHH24MISS');
  query(UserID ,querydate ,TotalNeedpay,state);
  dbms_output.put_line(TotalNeedpay||' '||State);
end;
  
查询
INSERT INTO "CLIENT" VALUES (2500, '张2500', '浑南区新秀街2500号', '13800002500');
INSERT INTO "DEVICE" VALUES (2500, 2500, '01', 2500);
INSERT INTO "RECEIVABLES" VALUES (2500, '201609', 2500, 100, '0');

INSERT INTO "CLIENT" VALUES (2501, '张2501', '浑南区新秀街2501号', '13800002501');
INSERT INTO "DEVICE" VALUES (2501, 2502, '02', 2501);
INSERT INTO "RECEIVABLES" VALUES (2501, '201609', 2501, 100, '0');

CREATE OR REPLACE PROCEDURE query
(
  UserID in client.Id%type,
  querydate in  date,
  TotalNeedpay out RECEIVABLES.basicfee%type,
  State out int
)
IS
result int;
needpay RECEIVABLES.basicfee%type;
CURSOR device IS select deviceid,type,yearmonth,basicfee  from device  join RECEIVABLES using(deviceid)where CLIENTID=UserID and flag='0';
BEGIN
select Count(*) into result
from Client
where ID=UserID;
if result=0 then
begin
  State:=0;
  needpay:=0.00;
end;
end if;
if result>0 then
begin
State:=1;
TotalNeedpay:=0.00;
for i in device Loop
   if i.type='01' then
     begin
     select basicfee   into needpay
     from RECEIVABLES
     where deviceid=i.deviceid and yearmonth=i.yearmonth;
     end;
     TotalNeedpay:=TotalNeedpay+needpay*1.18;
     begin
     if to_char(querydate,'YYYYMM')>i.yearmonth then
     TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.18*0.001;
     end if;
     end;
     end if;
    if i.type='02' then
     begin
     select basicfee into needpay
     from RECEIVABLES
     where yearmonth=i.yearmonth and deviceid=i.deviceid;
     end;
     TotalNeedpay:=TotalNeedpay+needpay*1.23;
     begin
      if to_char(querydate,'YYYYMM')>i.yearmonth then
      if substr(i.yearmonth,1,4)=to_char(querydate,'YYYY') then
      TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.23*0.002;
      end if;
     if  substr(i.yearmonth,1,4)<to_char(querydate,'YYYY')  then
        TotalNeedpay:=TotalNeedpay+(to_date(concat(to_char(querydate,'YYYY'),'0101'),'YYYYMMDD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.23*0.002
                     +(trunc(querydate,'DD')-to_date(concat(to_char(querydate,'YYYY'),'0101'),'YYYYMMDD'))*needpay*1.23*0.003;
      end if;

      end if;
      end;
     end if;
  end Loop;
end;
end if;
END;

declare
    PayEquipmentID  device.DEVICEID%type;
    PayBankNumber payfee.bankcode%type;
    paydate payfee.paydate%type;
    ReceiveMoney payfee.paymoney%type;
    PayBankSerial payfee.bankserial%type;
begin
    PayEquipmentID:=2501;
    PayBankNumber:='19';
    paydate:=TO_DATE('20161020000000', 'YYYYMMDDHH24MISS');
    ReceiveMoney:='150';
    PayBankSerial:='ZS2016102000'; 
    pay(PayEquipmentID,PayBankNumber, paydate,ReceiveMoney,PayBankSerial);   
end;

update RECEIVABLES set flag='0' where deviceid=2501;
delete from payfee where deviceid=2501;
update device set balance=0 where deviceid=2501;

CREATE OR REPLACE PROCEDURE Pay(
    PayEquipmentID in device.DEVICEID%type,
    PayBankNumber in payfee.bankcode%type,
    paydate IN payfee.paydate%type,
    ReceiveMoney in payfee.paymoney%type,
    PayBankSerial in payfee.bankserial%type
)
IS
Total RECEIVABLES.basicfee%type;
getID int;
devicetype device.type%type;
NeedPay RECEIVABLES.basicfee%type;
CURSOR result IS select basicfee,yearmonth from RECEIVABLES where deviceid=PayEquipmentID and flag='0'order by yearmonth;
begin
  begin
   select Count(*) into getID
   from PAYFEE;
  end;
  getID:=getID+1;
  begin
  insert into "PAYFEE" values(getID,PayEquipmentID ,ReceiveMoney,paydate,PayBankNumber,'2001',PayBankSerial);
  end;

  begin
  select Balance into Total
  from device
  where deviceid=PayEquipmentID;
  end;
  
  begin
   select type into devicetype
   from device
   where deviceid=PayEquipmentID;
  end;
  
  Total:=Total+ReceiveMoney;
  begin
   if devicetype='01' then
        FOR i IN result LOOP
          if to_char(paydate,'YYYYMM')>i.yearmonth then
           NeedPay:=i.basicfee*1.18+(trunc(paydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.18*0.001;
           dbms_output.put_line(NeedPay);
          else
           NeedPay:=i.basicfee*1.18;
          end if;
          if Total>=NeedPay then
             Total:=Total-NeedPay;
             update RECEIVABLES set flag='1' where deviceid=PayEquipmentID and yearmonth=i.yearmonth;
          else
             exit;
          end if;
        END LOOP;
        update device set balance=Total where deviceid=PayEquipmentID;
   end if;
   if  devicetype='02' then
         FOR i IN result LOOP
            if to_char(paydate,'YYYYMM')>i.yearmonth then
                if substr(i.yearmonth,1,4)=to_char(paydate,'YYYY') then
                    NeedPay:=i.basicfee*1.23+(trunc(paydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002;
                end if;
                if  substr(i.yearmonth,1,4)<to_char(paydate,'YYYY') then
                    NeedPay:=i.basicfee*1.23+(to_date(concat(to_char(paydate,'YYYY'),'0101'),'YYYYMMDD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002
                           +(trunc(paydate,'DD')-to_date(concat(to_char(paydate,'YYYY'),'0101'),'YYYYMMDD'))*i.basicfee*1.23*0.003;
                end if;
            else
                NeedPay:=i.basicfee*1.23;
            end if;

            if Total>=NeedPay then
                Total:=Total-NeedPay;
                update RECEIVABLES set flag='1' where deviceid=PayEquipmentID and yearmonth=i.yearmonth;
            else
              exit;
            end if;
       end Loop;
       update device set balance=Total where deviceid=PayEquipmentID;
  end if;
  end;
END;


declare
    originalEquipmentID  device.deviceid%type;
    originalBankNumber  payfee.bankcode%type;
    originalSerialNumber  payfee.bankserial%type;
    Operationdate  payfee.paydate%type;
    OperationMoney  payfee.paymoney%type;
    State  int;
begin
    originalEquipmentID:=2501;
    originalBankNumber:='19';
    Operationdate:=TO_DATE('20161020000000', 'YYYYMMDDHH24MISS');
    OperationMoney:='150';
    originalSerialNumber:='ZS2016102000'; 
    chongzheng(originalEquipmentID,originalBankNumber, originalSerialNumber, Operationdate,OperationMoney,State);
    dbms_output.put_line(State);   
end;
delete from payfee;
update device set balance=0 where deviceid=2500;

CREATE OR REPLACE PROCEDURE chongzheng(
    originalEquipmentID in device.deviceid%type,
    originalBankNumber in payfee.bankcode%type,
    originalSerialNumber in payfee.bankserial%type,
    Operationdate in payfee.paydate%type,
    OperationMoney in payfee.paymoney%type,
    State out int
)
IS
find int;
getID int;
nowbalance device.balance%type;
Money payfee.paymoney%type;
devicetype device.type%type;
TotalMoney RECEIVABLES.basicfee%type;
CURSOR result IS select * from RECEIVABLES where deviceid=originalEquipmentID and flag='1' Order by yearmonth DESC ;
begin
    select  Count(*) into find
    from payfee
    where bankserial=originalSerialNumber and OperationMoney=paymoney;
    if find=0 then
       State:=0;
       end if;
    if find>0 then
       State:=1;
       Money:=OperationMoney;
       begin
          select Balance into nowbalance
          from device
          where deviceid=originalEquipmentID;
       end;
       begin
       select type into devicetype
       from device
       where deviceid=originalEquipmentID;
       end;
       begin
        if devicetype='01' then
                for i in result LOOP
                  if trunc(Operationdate,'DD')>add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) then
                       TotalMoney:=i.basicfee*1.18+(trunc(Operationdate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1))*i.basicfee*1.18*0.001;
                  else
                       TotalMoney:=i.basicfee*1.18;
                  end if;
                if (TotalMoney+nowbalance)>Money then
                   nowbalance:=nowbalance+TotalMoney-Money;
                   begin
                   update device set Balance=nowbalance where deviceid=i.deviceid;
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                   end;
                   exit;
                  end if;
                if (TotalMoney+nowbalance)<=Money then
                   Money:=Money-TotalMoney;
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                  if nowbalance >=Money then
                    nowbalance:=nowbalance-Money;
                    begin
                    update device set Balance=nowbalance where deviceid=originalEquipmentID;
                    end;
                    exit;
                   end if;
                  end if;
                end LOOP;
        end if;
        if devicetype='02' then
                for i in result LOOP
                  
                  if trunc(Operationdate,'DD')>add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) then

                       if substr(i.yearmonth,1,4)=to_char(Operationdate,'YYYY') then
                         TotalMoney:=i.basicfee*1.23+(trunc(Operationdate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002;
                       end if;
                       if  substr(i.yearmonth,1,4)<to_char(Operationdate,'YYYY') then
                          TotalMoney:=i.basicfee*1.23+(to_date(concat(to_char(Operationdate,'YYYY'),'0101'),'YYYYMMDD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002
                           +(trunc(Operationdate,'DD')-to_date(concat(to_char(Operationdate,'YYYY'),'0101'),'YYYYMMDD'))*i.basicfee*1.23*0.003;
                       end if;

                  else
                       TotalMoney:=i.basicfee*1.23;
                  end if;
                  
                if (TotalMoney+nowbalance)>Money then
                   nowbalance:=nowbalance+TotalMoney-Money;
                   begin
                   update device set Balance=nowbalance where deviceid=i.deviceid;
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                   end;
                   exit;
                  end if;
                if (TotalMoney+nowbalance)<=Money then
                   Money:=Money-TotalMoney;
                   begin
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                   end;
                    if nowbalance >=Money then
                    nowbalance:=nowbalance-Money;
                    begin
                    update device set Balance=nowbalance where deviceid=originalEquipmentID;
                    end;
                    exit;
                  end if;
                 end if;
               end LOOP;
        end if;
       end;
      begin
       select Count(*) into getID
       from PAYFEE;
       end;
      getID:=getID+1;
      begin
      insert into "PAYFEE" values(getID,originalEquipmentID,OperationMoney,Operationdate,originalBankNumber,'2002',originalSerialNumber);
      end;
  end if;
end;


CREATE OR REPLACE PROCEDURE CheckTotal(
      CheckBankNumber in payfee.bankcode%type,
      CheckDate in payfee.paydate%type,
      State out int
)
IS
banktotalmoney CHECKRESULT.banktotalmoney%type;
ourtotalmoney  CHECKRESULT.ourtotalmoney%type;
banktotalcount CHECKRESULT.banktotalcount%type;
ourtotalcount  CHECKRESULT.ourtotalcount%type;
getID int;
begin

  begin
   select SUM(to_number(paymoney)),Count(*) into ourtotalmoney,ourtotalcount
   from payfee
   where (trunc(CheckDate,'DD')-1)=trunc(paydate,'DD') and type='2001' and bankcode=CheckBankNumber;
  end;

  begin
     select SUM(payfee),Count(*) into banktotalmoney,banktotalcount
     from BANKRECORD
     where  (trunc(CheckDate,'DD')-1)=to_date(substr(bankserial,3,8),'YYYYMMDD');
  end;

   begin
       select Count(*) into getID
       from checkresult;
   end;
   getID:=getID+1;
   begin
   insert into "CHECKRESULT" values(getID,CheckDate,CheckBankNumber,banktotalcount,banktotalmoney,ourtotalcount,ourtotalmoney);
   end;
   if banktotalcount=ourtotalcount then
        if banktotalmoney=ourtotalmoney then
          State:=1;
        else
          State:=0;
          CheckDetail(CheckBankNumber, CheckDate);
        end if;
    else
       State:=0;
          CheckDetail(CheckBankNumber, CheckDate);
    end if;

end;


CREATE OR REPLACE PROCEDURE CheckDetail(
      CheckBankNumber in payfee.bankcode%type,
      CheckDate in payfee.paydate%type
)
IS
getID int;
calcute int;
bankmoney BANKRECORD.payfee%type;
CURSOR ourrecord is select paymoney,bankserial from payfee where (trunc(CheckDate,'DD')-1)=trunc(paydate,'DD') and type='2001' and bankcode=CheckBankNumber;
CURSOR bankrrecord is select payfee,bankserial from BANKRECORD where  (trunc(CheckDate,'DD')-1)=to_date(substr(bankserial,3,8),'YYYYMMDD');
BEGIN
  begin
       select Count(*) into getID
       from check_exception;
   end;
    for i in ourrecord Loop
        begin
         select count(*) into calcute
         from BANKRECORD
         where i.bankserial=BANKRECORD.bankserial;
        end;
        if calcute=0 then
           getID:=getID+1;
           insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,i.bankserial,0,i.paymoney,'001');
        else
         begin
         select payfee into bankmoney
         from BANKRECORD
         where i.bankserial=BANKRECORD.bankserial;
         end;
          if i.paymoney<>bankmoney then
            getID:=getID+1;
            insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,i.bankserial,bankmoney,i.paymoney,'002');
          end if;
        end if;
    end Loop;

    for i in bankrrecord Loop
        begin
         select count(*) into calcute
         from payfee
         where i.bankserial=payfee.bankserial;
        end;
        if calcute=0 then
            getID:=getID+1;
           insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,i.bankserial,i.payfee,0,'003');
        end if;
    end Loop;


END;
