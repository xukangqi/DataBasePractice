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
 * Created by Administrator on 2016/12/11.
 */
@WebServlet("/Servlet/Check")
public class Check extends HttpServlet {//接受jsp发送过来的表单，并且调用对账存储过程，返回相关结果

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
            // 根据jsp界面中选中的银行，获取银行代码
            String query = String.format("SELECT CODE FROM Bank where NAME=\'" + request.getParameter("bankname") + "\'");
            Statement statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery(query);
            resultSet.next();
            CallableStatement callableStatement = connection.prepareCall("call checktotal(?,?,?)");//调用对总账存储过程
            callableStatement.setString(1, resultSet.getString(1));
            callableStatement.setDate(2, java.sql.Date.valueOf(request.getParameter("checktime")));
            callableStatement.registerOutParameter(3, Types.INTEGER);
            callableStatement.execute();
            int State = callableStatement.getInt(3);
            if (State == 0) {//如果返回数值为0，代表账单有问题，因为此时存储过程已经调用了对明细存储过程
                //所以直接从对账异常表中查询出当天的记录即可
                result = "  <table class='table table-hover table-striped' >" +
                        "<caption><center>对账异常信息</center></caption>" +
                        " <tbody><th>银行流水号</th><th>银行记录金额</th><th>公司记录金额</th><th>错误类型</th>";
                String[] array = new String[3];
                array = request.getParameter("checktime").split("-");//因为java中data为YYYY-MM-DD格式
                //需要处理字符串变成 YYYYMMDD格式用于数据库处理
                String time = "";
                for (String s : array) {
                    time += s;
                }
                query = String.format("SELECT bankserial,bankmoney,ourmoney,exceptiontype FROM CHECK_EXCEPTION WHERE to_char(checkdate,'YYYYMMDD')=" + "\'" + time + "\'");//查询对账异常表
                resultSet = statement.executeQuery(query);
                int count = 0;
                while (resultSet.next()) {
                    count++;
                    result += "<tr><td>" + resultSet.getString(1) + "</td><td>" + resultSet.getString(2) + "</td><td>" + resultSet.getString(3) + "</td><td>" + resultSet.getString(4) + "</td></tr>";
                    if (count > 5) {//因为页面空间有限，只显示5条结果
                        break;
                    }
                }
                result += "</tbody></table>";
            } else {
                result = "账单无误";
            }
            callableStatement.close();
            statement.close();
            connection.close();
            String str = "{\"message\":\"" + result + "\",\"find\":\"" + State + "\"}";
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
