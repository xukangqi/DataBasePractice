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
 * Created by Administrator on 2016/12/14.
 */
@WebServlet("/Servlet/Querydetail")
public class Querydetail extends HttpServlet {//接受jsp发送过来的表单，并且调用查询细节存储过程，返回相关结果
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
            CallableStatement callableStatement = connection.prepareCall("call querydetail(?,?,?,?)");//调用存储过程
            callableStatement.setInt(1, Integer.parseInt(request.getParameter("deviceid")));
            callableStatement.setDate(2, java.sql.Date.valueOf(request.getParameter("querytime")));
            callableStatement.registerOutParameter(3, Types.DOUBLE);
            callableStatement.registerOutParameter(4, Types.INTEGER);
            callableStatement.execute();
            double i = callableStatement.getDouble(3);
            int j = callableStatement.getInt(4);
            if (j == 1) {//返回状态为1，表示找到了该设备
                result = "应缴费用：" + i;
            } else {
                result = "找不到该设备！！";
            }
            callableStatement.close();
            connection.close();
            String str = "{\"message\":\"" + result + "\",\"success\":\"true\"}";
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
