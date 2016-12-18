package Servlet;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * Created by Administrator on 2016/12/10.
 */
@WebServlet("/Servlet/Pay")
public class Pay extends HttpServlet {//接受jsp发送过来的表单，并且调用缴费存储过程，返回相关结果
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String result;
            String driver = "oracle.jdbc.driver.OracleDriver";
            String protocol = "jdbc:oracle:";
            Class.forName(driver);
            String dbUrl = protocol + "thin:@127.0.0.1:1521:XE";
            String user = "xu";
            String password = "1234";
            Connection connection = DriverManager.getConnection(dbUrl, user, password);//连接数据库
            //根据jsp界面中选中的银行，获取银行代码
            String query = String.format("SELECT CODE FROM Bank where NAME=\'" + request.getParameter("bankname")+"\'");
            Statement statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery(query);
            resultSet.next();
            String banknumber=resultSet.getString(1);//获取银行代码
            CallableStatement callableStatement = connection.prepareCall("call pay(?,?,?,?,?)");//调用缴费存储过程
            callableStatement.setInt(1,Integer.parseInt(request.getParameter("deviceid")));
            callableStatement.setString(2,banknumber);
            callableStatement.setDate(3,java.sql.Date.valueOf(request.getParameter("paytime")));
            callableStatement.setString(4,request.getParameter("paynumber"));
            callableStatement.registerOutParameter(5,Types.INTEGER);
            callableStatement.execute();//执行存储过程
            int State=callableStatement.getInt(5);
            if (State==1){//如果返回状态为1，代表缴费成功
                //返回当前设备还未缴费的记录
                result="  <table class='table table-hover table-striped' >" +
                        "<caption><center>当前设备欠费信息汇总</center></caption>"+
                        " <tbody> <th>设备ID</th><th>应缴费月份</th><th>基本费用</th>";
                query=String.format("SELECT deviceid,yearmonth,basicfee FROM RECEIVABLES where flag='0' and deviceid=" +Integer.parseInt(request.getParameter("deviceid"))+"order by yearmonth");
                resultSet = statement.executeQuery(query);
                int count=0;
                while (resultSet.next()){
                    count++;
                    result+="<tr><td>"+resultSet.getString(1)+"</td><td>"+resultSet.getString(2)+"</td><td>"+resultSet.getDouble(3)+"</td></tr>";
                    if (count>3){
                        break;
                    }
                }
                result+="</table>";
            }else {
                result = "缴费失败";
            }
            callableStatement.close();
            statement.close();
            connection.close();
            String str = "{\"message\":\"" + result + "\",\"find\":\""+State+"\"}";
            response.setContentType("text/json");
            response.setCharacterEncoding("UTF-8");
            PrintWriter out = response.getWriter();
            out.write(str);//返回json数据
            out.flush();
        } catch (SQLException e) {
        } catch (ClassNotFoundException c) {

        }

    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

    }
}
