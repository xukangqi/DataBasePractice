<%@ page import="java.sql.*" %>
<%@ page import="java.time.LocalDate" %>
<%--
  Created by IntelliJ IDEA.
  User: Administrator
  Date: 2016/12/10
  Time: 10:17
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<html>
<head>
    <title>电力缴费系统</title>
    <%--引入自己写的css样式--%>
    <link href="css/main.css" rel="stylesheet">
    <%--引入bootstrap--%>
    <link href="css/bootstrap.css" rel="stylesheet">
    <%--引入jquery--%>
    <script src="javascript/jquery.js" rel="script"></script>
    <%--引入自己写的js代码，用于和后台交互--%>
    <script src="javascript/main.js" rel="script"></script>
</head>
<body>
<%
    try {
        String driver = "oracle.jdbc.driver.OracleDriver";
        String protocol = "jdbc:oracle:";
        Class.forName(driver);
        String dbUrl = protocol + "thin:@127.0.0.1:1521:XE";
        String user = "xu";
        String password = "1234";
        ResultSet resultSet;
        ResultSet newresultSet;
        Connection connection = DriverManager.getConnection(dbUrl, user, password);//连接数据库
        Statement statement = connection.createStatement();
%>
<%--导航栏--%>
<nav class="navbar navbar-default" role="navigation">
    <div class="container-fluid">
        <div class="navbar-header">
            <a class="navbar-brand" href="#">电力缴费系统</a>
        </div>
        <div class="collapse navbar-collapse ">
            <ul class="nav navbar-nav  " id="table">
                <li class="active"><a href="#">首页</a></li>
                <li><a href="#querypart">欠费用户信息</a></li>
                <li><a href="#paypart">缴费</a></li>
                <li><a href="#reversepart">冲正</a></li>
                <li><a href="#checkpart">对账</a></li>
            </ul>
        </div>
    </div>
</nav>

<img src="background.jpeg" width="1920px" height="600px">

<div class="main">

    <%--查询模块--%>
    <div id="querypart">
        <%--首先展示当前数据库中欠费记录最多的十个用户--%>
        <div style="width: 800px;margin-left: 250px">
            <table class="table table-hover table-striped">
                <caption style="font-size: 30px">
                    <center>欠费用户信息</center>
                </caption>
                <tbody>
                <tr>
                    <th>ID</th>
                    <th>用户姓名</th>
                    <th>电话号码</th>
                    <th>欠费金额</th>
                </tr>
                <%
                    CallableStatement callableStatement = connection.prepareCall("call query(?,?,?,?)");
                    double needpay;
                    int State;
                    int id = 0;
                    int count = 0;
                    String query = String.format("select id,record from(select client.id,count(*) as record" +
                            " from CLIENT join DEVICE on  CLIENT.id=DEVICE.clientid  join RECEIVABLES using(deviceid)" +
                            " where flag='0'  GROUP by CLIENT.id ) order by record desc");//查询所有用户的欠费记录总条数
                    //从大到小排列
                    resultSet = statement.executeQuery(query);
                    Statement newstatement = connection.createStatement();//新开一个statement获取用户的其他个人信息
                    while (resultSet.next()) {
                        count++;
                        if (count < 10) {//只显示前十的用户欠费信息
                            //调用存储过程获取该用户欠费金额
                            id = resultSet.getInt(1);
                            callableStatement.setInt(1, id);
                            callableStatement.setDate(2, Date.valueOf(LocalDate.now()));
                            callableStatement.registerOutParameter(3, Types.DOUBLE);
                            callableStatement.registerOutParameter(4, Types.INTEGER);
                            callableStatement.execute();
                            needpay = callableStatement.getDouble(3);
                            State = callableStatement.getInt(4);
                            query = String.format("select * from CLIENT where ID=" + id);//使用query获取这个用户的其他信息
                            newresultSet = newstatement.executeQuery(query);
                            newresultSet.next();
                %>
                <tr>
                    <td><%=newresultSet.getString("id")%>
                    </td>
                    <td><%=newresultSet.getString("name")%>
                    </td>
                    <td><%=newresultSet.getString("tel")%>
                    </td>
                    <%
                        if (State == 1) {//如果查询成功
                    %>
                    <td><%=needpay%>
                    </td>
                    <%
                    } else {//查询失败
                    %>
                    <td>0.00</td>
                    <%
                        }
                    %>
                </tr>
                <%
                        } else {
                            break;
                        }
                    }
                %>
                </tbody>
            </table>
        </div>
        <br><br><br>
        <%--可以利用表单提交查询任意用户的欠费总额--%>
        <form class="form-horizontal" role="form" id="query" style="width: 900px;margin-left: 150px">
            <div class="form-group">
                <label class="col-sm-2 control-label">ID</label>
                <div class="col-sm-10">
                    <input type="text" class="form-control" placeholder="请输入用户id" name="userid" required>
                </div>
            </div>
            <div class="form-group">
                <label class="col-sm-2 control-label">时间</label>
                <div class="col-sm-10">
                    <input type="date" class="form-control" name="querytime" required>
                </div>
            </div>
        </form>
        <%--提交按钮，调用js方法发送给后台--%>
        <div>
            <div style="margin-left: 600px">
                <div>
                    <button type="button" class="btn btn-default" onclick="query();return false;">查询</button>
                </div>
            </div>
        </div>
        <br><br><br>


        <%--查询单个设备欠费的表单--%>
        <div style="clear: both">
            <form class="form-horizontal" role="form" id="querydetail" style="width: 900px;margin-left: 150px">
                <div class="form-group">
                    <label class="col-sm-2 control-label">设备ID</label>
                    <div class="col-sm-10">
                        <input type="text" class="form-control" placeholder="请输入设备id" name="deviceid" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">时间</label>
                    <div class="col-sm-10">
                        <input type="date" class="form-control" name="querytime" required>
                    </div>
                </div>
            </form>
            <%--提交按钮，调用js方法发送给后台--%>
            <div>
                <div style="margin-left: 600px">
                    <div>
                        <button type="button" class="btn btn-default" onclick="querydetail();return false;">查询</button>
                    </div>
                </div>
            </div>
        </div>

        <br><br><br>
        <%--用户缴费表单--%>
        <div id="paypart" style="clear: both;width: 900px;margin-left: 150px">
            <%
                query = String.format("SELECT name FROM BANK");//查询当前可用的银行列表
                resultSet = statement.executeQuery(query);
                callableStatement = connection.prepareCall("call query(?,?,?,?)");
            %>

            <form class="form-horizontal" role="form" id="pay">
                <div class="form-group">
                    <label class="col-sm-2 control-label">设备ID</label>
                    <div class="col-sm-10">
                        <input type="text" class="form-control" placeholder="请输入需要缴费的设备id" name="deviceid" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">支持银行</label>
                    <div class="col-sm-10">
                        <select class="form-control" name="bankname">
                            <%
                                while (resultSet.next()) {//下拉栏显示银行名字
                            %>
                            <option><%=resultSet.getString(1)%>
                            </option>
                            <%
                                }
                            %>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">缴费时间</label>
                    <div class="col-sm-10">
                        <input type="date" class="form-control" name="paytime" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">缴费金额</label>
                    <div class="col-sm-10">
                        <input type="number" class="form-control" min="0" name="paynumber" required>
                    </div>
                </div>
            </form>
            <%--提交按钮，调用js方法发送给后台--%>
            <div style=" clear:both;margin-left: 450px">
                <div>
                    <button type="button" class="btn btn-default" onclick="pay();return false;">缴费</button>
                </div>
            </div>

        </div>
        <%--此处div用于显示后台发送过来的该设备未缴费记录--%>
        <div id="unpay" style="width: 800px;margin-left: 250px"></div>
        <br><br><br>

        <%--冲正模块--%>
        <div id="reversepart" style="clear: both;width: 900px;margin-left: 150px">
            <%
                query = String.format("SELECT name FROM BANK");
                resultSet = statement.executeQuery(query);
                callableStatement = connection.prepareCall("call query(?,?,?,?)");
            %>
            <form class="form-horizontal" role="form" id="reverse">
                <div class="form-group">
                    <label class="col-sm-2 control-label">设备ID</label>
                    <div class="col-sm-10">
                        <input type="text" class="form-control" placeholder="请输入需要冲正的设备id" name="deviceid" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">原缴费流水号</label>
                    <div class="col-sm-10">
                        <input type="text" class="form-control" placeholder="请输入原缴费流水号" name="bankserial" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">选择当时缴费的银行</label>
                    <div class="col-sm-10">
                        <select class="form-control" name="bankname">
                            <%
                                while (resultSet.next()) {//下拉栏显示银行
                            %>
                            <option><%=resultSet.getString(1)%>
                            </option>
                            <%
                                }
                            %>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">冲正时间</label>
                    <div class="col-sm-10">
                        <input type="date" class="form-control" name="reversetime" required>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">冲正金额</label>
                    <div class="col-sm-10">
                        <input type="number" class="form-control" min="0" name="reversenumber" required>
                    </div>
                </div>
            </form>
            <%--提交按钮，调用js方法发送给后台--%>
            <div style=" clear:both;margin-left: 450px">
                <div>
                    <button type="button" class="btn btn-default" onclick="reverse();return false;">冲正</button>
                </div>
            </div>
        </div>
        <%--此处div用于显示后台发送过来的该设备未缴费记录--%>
        <div id="reverseresult" style="width: 800px;margin-left: 250px"></div>
        <br><br><br><br>

        <%--对账模块--%>
        <div id="checkpart" style="clear: both;width: 900px;margin-left: 150px">
            <%
                query = String.format("SELECT name FROM BANK");
                resultSet = statement.executeQuery(query);
                callableStatement = connection.prepareCall("call query(?,?,?,?)");
            %>
            <form class="form-horizontal" role="form" id="check">
                <div class="form-group">
                    <label class="col-sm-2 control-label">选择需要对账的银行</label>
                    <div class="col-sm-10">
                        <select class="form-control" name="bankname">
                            <%
                                while (resultSet.next()) {
                            %>
                            <option><%=resultSet.getString(1)%>
                            </option>
                            <%
                                }
                            %>
                        </select>
                    </div>
                </div>
                <div class="form-group">
                    <label class="col-sm-2 control-label">对账时间</label>
                    <div class="col-sm-10">
                        <input type="date" class="form-control" name="checktime" required>
                    </div>
                </div>
            </form>
            <%--提交按钮，调用js方法发送给后台--%>
            <div style=" clear:both;margin-left: 450px">
                <div>
                    <button type="button" class="btn btn-default" onclick="check();return false;">对账</button>
                </div>
            </div>
            <%--此处div用于显示后台发送过来的对账异常记录--%>
            <div id="checkdetail" style="clear: both"></div>

        </div>
        <br><br>
        <br><br>
        <br><br>
            <%
    }catch (SQLException S){

    }
  %>
</body>
</html>
