CREATE OR REPLACE PROCEDURE query
-- 输入信息包括用户id，查询日期，输出用户欠费总额和是否查询成功的标志
(
  UserID in client.Id%type,
  querydate in  date,
  TotalNeedpay out RECEIVABLES.basicfee%type,
  State out int
)
IS
result int;
needpay RECEIVABLES.basicfee%type;
-- 游标获取该用户所有设备的未缴费记录
CURSOR device IS select deviceid,type,yearmonth,basicfee  from device  join RECEIVABLES using(deviceid)where CLIENTID=UserID and flag='0';
BEGIN
-- 在client表中查询用户ID，如果存在该用户，应该存在查询结果
select Count(*) into result
from Client
where ID=UserID;
if result=0 then
begin
  State:=0;
  needpay:=0.00;
end;
end if;
-- 如果存在该用户
if result>0 then
begin
State:=1;
TotalNeedpay:=0.00;
for i in device Loop--依次取出游标中的每一行未缴费记录，计算应缴费用
   if i.type='01' then--不同类型的设备计费方式不同
     begin
     select basicfee   into needpay
     from RECEIVABLES
     where deviceid=i.deviceid and yearmonth=i.yearmonth;
     end;
     TotalNeedpay:=TotalNeedpay+needpay*1.18;  --计算基本费用+附加费用
     begin
     if to_char(querydate,'YYYYMM')>i.yearmonth then  --如果查询日期比该记录应缴费年月
     -- 要大，意味着要收违约金，默认从应缴费记录的下个月1号开始计算
     TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.18*0.001;
     end if;
     end;
     end if;
    if i.type='02' then   --如果是企业用设备
     begin
     select basicfee into needpay
     from RECEIVABLES
     where yearmonth=i.yearmonth and deviceid=i.deviceid;
     end;
     TotalNeedpay:=TotalNeedpay+needpay*1.23;
     begin
      if to_char(querydate,'YYYYMM')>i.yearmonth then  --如果存在欠费现象
      if substr(i.yearmonth,1,4)=to_char(querydate,'YYYY') then --如果欠费记录没有跨年
      TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.23*0.002;
      end if;
     if  substr(i.yearmonth,1,4)<to_char(querydate,'YYYY')  then --如果欠费记录跨年，分开年内和跨年的违约金
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




CREATE OR REPLACE PROCEDURE Pay(
    --输入参数包括需要缴费的设备ID，缴费的银行代码，缴费日期，缴费金额，输出缴费是否成功
    PayEquipmentID in device.DEVICEID%type,
    PayBankNumber in payfee.bankcode%type,
    paydate IN payfee.paydate%type,
    ReceiveMoney in payfee.paymoney%type,
    State out int
)
IS
Total RECEIVABLES.basicfee%type;
PayBankSerial payfee.bankserial%type;
getID int;
bankid int;
devicetype device.type%type;
NeedPay RECEIVABLES.basicfee%type;
--游标获取该设备未缴费记录
CURSOR result IS select basicfee,yearmonth from RECEIVABLES where deviceid=PayEquipmentID and flag='0'order by yearmonth;
begin
  begin  --判断是否存在该设备
   select Count(*) into State
   from device
   where deviceid=PayEquipmentID;
  end;
  if  State=1 then  --如果存在该设备，则可以缴费
  begin
   select Count(*) into getID
   from PAYFEE;
  end;
  getID:=getID+1;  --缴费记录的id根据缴费表中的记录算出，防止重复
  begin
    --根据 银行编码+缴费日期+00+缴费记录ID的顺序生成银行流水号
    PayBankSerial:=concat(concat(PayBankNumber,to_char(paydate,'YYYYMMDD')),concat('00',getID));
  end;
  begin  --银行记录的ID根据缴费记录表中的记录算出，防止重复
    select Count(*) into bankid
    from bankrecord;
  end;
  bankid:=bankid+1;  
  begin
  --同时在电力公司的缴费记录表和银行的记录表中记录该条缴费信息
  insert into "PAYFEE" values(getID,PayEquipmentID ,ReceiveMoney,paydate,PayBankNumber,'2001',PayBankSerial);
  insert into "BANKRECORD" values(bankid,ReceiveMoney,PayBankNumber,PayBankSerial);
  end;

  begin  --获取设备余额
  select Balance into Total
  from device
  where deviceid=PayEquipmentID;
  end;
  
  begin  --获取设备类型
   select type into devicetype
   from device
   where deviceid=PayEquipmentID;
  end;
  
  Total:=Total+ReceiveMoney;  --设备余额+缴费金额 合起来为用户可用于缴费的金额
  begin
   if devicetype='01' then
        FOR i IN result LOOP
          if to_char(paydate,'YYYYMM')>i.yearmonth then --判断是否需要付违约金
           --计算基本费用+附加费用+违约金
           NeedPay:=i.basicfee*1.18+(trunc(paydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.18*0.001;
          else
          --计算基本费用+附加费用
           NeedPay:=i.basicfee*1.18;
          end if;
          if Total>=NeedPay then  --如果所拥有的总的钱比需要缴费的金额多，表示可以缴费
             Total:=Total-NeedPay; --减去这部分费用
             update RECEIVABLES set flag='1' where deviceid=PayEquipmentID and yearmonth=i.yearmonth; --设置该月已缴费
          else --如果剩余金额不足以缴费
             exit;
          end if;
        END LOOP;
        update device set balance=Total where deviceid=PayEquipmentID; --剩余的钱变成余额
   end if;
   if  devicetype='02' then --如果设备类型为02
         FOR i IN result LOOP
            if to_char(paydate,'YYYYMM')>i.yearmonth then  --判断是否需要交违约金
                if substr(i.yearmonth,1,4)=to_char(paydate,'YYYY') then --如果欠费记录没有跨年
                    NeedPay:=i.basicfee*1.23+(trunc(paydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002;
                end if;
                if  substr(i.yearmonth,1,4)<to_char(paydate,'YYYY') then --如果缴费记录跨年，分开计算违约金
                    NeedPay:=i.basicfee*1.23+(to_date(concat(to_char(paydate,'YYYY'),'0101'),'YYYYMMDD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*i.basicfee*1.23*0.002
                           +(trunc(paydate,'DD')-to_date(concat(to_char(paydate,'YYYY'),'0101'),'YYYYMMDD'))*i.basicfee*1.23*0.003;
                end if;
            else --不需要计算违约金
                NeedPay:=i.basicfee*1.23;
            end if;

            if Total>=NeedPay then --如果所拥有的总的钱比需要缴费的金额多，表示可以缴费
                Total:=Total-NeedPay;
                update RECEIVABLES set flag='1' where deviceid=PayEquipmentID and yearmonth=i.yearmonth;
            else
              exit;
            end if;
       end Loop;
       update device set balance=Total where deviceid=PayEquipmentID; --剩余的钱变成余额
   end if;
  end if;
  end;
  end if;
END;


CREATE OR REPLACE PROCEDURE chongzheng(
    --需要输入冲正的设备ID，付款时的银行代码，流水号，金额和冲正的日期
    --容错处理主要在java中实现，此处仅判断冲正金额是否正确
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
begin  --查找该流水号的冲正金额是否正确
    select  Count(*) into find
    from payfee
    where bankserial=originalSerialNumber and OperationMoney=paymoney;
    if find=0 then
       State:=0;
       end if;
    if find>0 then --如果正确
       State:=1;
       Money:=OperationMoney;
       begin  --获取设备余额
          select Balance into nowbalance
          from device
          where deviceid=originalEquipmentID;
       end;
       begin  --获取设备类型
       select type into devicetype
       from device
         where deviceid=originalEquipmentID;
       end;
       begin
        if devicetype='01' then
                for i in result LOOP 
                --此处思路为依次取出该设备的最新的应缴费用中的已交费记录，计算用户应该为此付的钱，通过将设备已交费记录
                --变更为未缴费，来获取冲正所要扣去的钱
                  if nowbalance >=Money then --如果余额比此时冲正所需要金额要多，则直接在余额中扣除，结束循环
                    nowbalance:=nowbalance-Money;
                    begin
                    update device set Balance=nowbalance where deviceid=originalEquipmentID;
                    end;
                    exit;
                   end if;
                  if trunc(Operationdate,'DD')>add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) then
                     --冲正默认是缴费当天进行的，所以计算违约金的方法也与缴费一致
                       TotalMoney:=i.basicfee*1.18+(trunc(Operationdate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1))*i.basicfee*1.18*0.001;
                  else
                       TotalMoney:=i.basicfee*1.18;
                  end if;
                if (TotalMoney+nowbalance)>Money then --如果能满足冲正扣去金额的要求
                   nowbalance:=nowbalance+TotalMoney-Money; --重新设置余额
                   begin--更新设备余额和应缴费记录，结束循环
                   update device set Balance=nowbalance where deviceid=i.deviceid;
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                   end;
                   exit;
                  end if;
                if (TotalMoney+nowbalance)<=Money then --如果还无法满足冲正金额，则需要继续找下一条记录扣除金额
                   Money:=Money-TotalMoney;
                   update RECEIVABLES set flag='0' where deviceid=i.deviceid and yearmonth=i.yearmonth;
                  end if;
                end LOOP;
        end if;
        if devicetype='02' then --此处与设备类型为01时的操作基本类似，只是在计算违约金时要判断是否跨年
                for i in result LOOP
                  if nowbalance >=Money then
                    nowbalance:=nowbalance-Money;
                    begin
                    update device set Balance=nowbalance where deviceid=originalEquipmentID;
                    end;
                    exit;
                  end if;
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
                 end if;
               end LOOP;
        end if;
       end;
      begin --生成冲正记录ID
       select Count(*) into getID
       from PAYFEE;
       end;
      getID:=getID+1;
      begin --插入冲正记录
      insert into "PAYFEE" values(getID,originalEquipmentID,OperationMoney,Operationdate,originalBankNumber,'2002',originalSerialNumber);
      end;
  end if;
end;


CREATE OR REPLACE PROCEDURE CheckTotal( 
     --需要输入对账日期和需要对账的银行代码，输出账单是否有误
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

  begin --从电力公司记录中获取对账日期前一天所有的用该银行缴费的记录
   select SUM(to_number(paymoney)),Count(*) into ourtotalmoney,ourtotalcount
   from payfee
   where trunc(paydate,'DD')=(trunc(CheckDate,'DD')-1) and type='2001' and bankcode=CheckBankNumber;
  end;

  begin --从银行记录中获取对账日期前一天所有的用该银行缴费的记录
     select SUM(payfee),Count(*) into banktotalmoney,banktotalcount
     from BANKRECORD
     where  to_date(substr(bankserial,3,8),'YYYYMMDD')=(trunc(CheckDate,'DD')-1) and bankcode=CheckBankNumber;
  end;

   begin --计算ID
       select Count(*) into getID
       from checkresult;
   end;
   getID:=getID+1;
   begin  --插入对账结果表
   insert into "CHECKRESULT" values(getID,CheckDate,CheckBankNumber,banktotalcount,banktotalmoney,ourtotalcount,ourtotalmoney);
   end;
   if banktotalcount=ourtotalcount then --如果总笔数一致
        if banktotalmoney=ourtotalmoney then  --如果总金额一致
          State:=1;  --对账成功
        else
          State:=0; --对账失败
          CheckDetail(CheckBankNumber, CheckDate); --对明细
        end if;
    else
       State:=0;   --对账失败
          CheckDetail(CheckBankNumber, CheckDate); --对明细
    end if;

end;

CREATE OR REPLACE PROCEDURE CheckDetail(
  --需要获取需要对账的银行代码和对账日期
      CheckBankNumber in payfee.bankcode%type,
      CheckDate in payfee.paydate%type
)
IS
getID int;
calcute int;
bankmoney BANKRECORD.payfee%type;
--利用游标获取对账日期前一天的所有该银行缴费的记录
CURSOR ourrecord is select paymoney,bankserial from payfee where (trunc(CheckDate,'DD')-1)=trunc(paydate,'DD') and type='2001' and bankcode=CheckBankNumber;
CURSOR bankrrecord is select payfee,bankserial from BANKRECORD where  (trunc(CheckDate,'DD')-1)=to_date(substr(bankserial,3,8),'YYYYMMDD') and bankcode=CheckBankNumber;
BEGIN
  begin
       select Count(*) into getID
       from check_exception;
   end;
    for i in ourrecord Loop --从电力公司的记录中依次读取记录
        begin --判断银行记录中是否包含电力公司记录中有的流水号
         select count(*) into calcute 
         from BANKRECORD
         where i.bankserial=BANKRECORD.bankserial;
        end;
        if calcute=0 then --如果不存在，记录在对账异常表中
           getID:=getID+1;
           insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,i.bankserial,0,i.paymoney,'001');
        else --如果存在，则需要核对金额
         begin --获取银行记录中该流水号的缴费金额
         select payfee into bankmoney
         from BANKRECORD
         where i.bankserial=BANKRECORD.bankserial;
         end;
          if i.paymoney<>bankmoney then --如果金额不等，加入到对账异常表
            getID:=getID+1;
            insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,i.bankserial,bankmoney,i.paymoney,'002');
          end if;
        end if;
    end Loop;

    for j in bankrrecord Loop --从银行的记录中依次读取记录
        begin  --查找银行记录的流水号是否存在于电力公司的记录中
         select count(*) into calcute 
         from payfee
         where j.bankserial=payfee.bankserial;
        end;
        if calcute=0 then --如果不存在，记录在对账异常表中
            getID:=getID+1;
           insert into "CHECK_EXCEPTION" values(getID,CheckDate, CheckBankNumber,j.bankserial,j.payfee,0,'003');
        end if;
    end Loop;

END;

CREATE OR REPLACE PROCEDURE querydetail
--为了方便用户查看欠费信息，所以增加这个存储过程来对某一设备进行欠费查找
-- 输入信息包括设备id，查询日期，输出设备欠费总额和是否查询成功的标志
(
  queryDeviceID in device.deviceid%type,
  querydate in  date,
  TotalNeedpay out RECEIVABLES.basicfee%type,
  State out int
)
IS
result int;
devicetype number(4);
needpay RECEIVABLES.basicfee%type;
-- 游标获取该设备的未缴费记录
CURSOR device IS select yearmonth,basicfee  from device  join RECEIVABLES using(deviceid)where deviceid=queryDeviceID and flag='0';
BEGIN
-- 在device表中查询设备ID，如果存在该设备，应该存在查询结果
select Count(*) into result
from device
where deviceid=queryDeviceID;
if result=0 then
begin
  State:=0;
  needpay:=0.00;
end;
end if;
-- 如果存在该设备
if result>0 then
begin
select type into devicetype
from device
where deviceid=queryDeviceID;
end;
begin
State:=1;
TotalNeedpay:=0.00;
if devicetype='01' then --不同类型的设备计费方式不同
for i in device Loop--依次取出游标中的每一行未缴费记录，计算应缴费用
      needpay:=i.basicfee;
     TotalNeedpay:=TotalNeedpay+needpay*1.18;  --计算基本费用+附加费用
     begin
     if to_char(querydate,'YYYYMM')>i.yearmonth then  --如果查询日期比该记录应缴费年月
     -- 要大，意味着要收违约金，默认从应缴费记录的下个月1号开始计算
     TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.18*0.001;
     end if;
     end;
     end Loop;
     end if;
if devicetype='02' then   --如果是企业用设备
for i in device Loop
     needpay:=i.basicfee;
     TotalNeedpay:=TotalNeedpay+needpay*1.23;
     begin
      if to_char(querydate,'YYYYMM')>i.yearmonth then  --如果存在欠费现象

      if substr(i.yearmonth,1,4)=to_char(querydate,'YYYY') then --如果欠费记录没有跨年
      TotalNeedpay:=TotalNeedpay+(trunc(querydate,'DD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.23*0.002;
      end if;
     if  substr(i.yearmonth,1,4)<to_char(querydate,'YYYY')  then --如果欠费记录跨年，分开年内和跨年的违约金
        TotalNeedpay:=TotalNeedpay+(to_date(concat(to_char(querydate,'YYYY'),'0101'),'YYYYMMDD')-add_months(to_date(concat(i.yearmonth,'01'),'YYYYMMDD'),1) )*needpay*1.23*0.002
                     +(trunc(querydate,'DD')-to_date(concat(to_char(querydate,'YYYY'),'0101'),'YYYYMMDD'))*needpay*1.23*0.003;
      end if;

      end if;
       end;
      end Loop;
     
     end if;
end;
end if;
END;