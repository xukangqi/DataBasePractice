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
@WebServlet("/Servlet/Reverse")
public class Reverse extends HttpServlet {//用于返回冲正结果
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        try {
            String result;
            String driver = "oracle.jdbc.driver.OracleDriver";
            String protocol = "jdbc:oracle:";
            Class.forName(driver);
            String dbUrl = protocol + "thin:@127.0.0.1:1521:XE";
            String user = "xu";
            String password = "1234";
            int State=0;
            Connection connection = DriverManager.getConnection(dbUrl, user, password);//连接数据库
            //根据jsp界面中选中的银行，获取银行代码
            String query = String.format("SELECT CODE FROM Bank where NAME=\'" + request.getParameter("bankname")+"\'");
            Statement statement = connection.createStatement();
            ResultSet resultSet = statement.executeQuery(query);
            resultSet.next();
            String banknumber=resultSet.getString(1);
            //计算该流水号是否存在于电力公司记录中
            query=String.format("SELECT COUNT(*) from PAYFEE where bankserial=\'" + request.getParameter("bankserial")+"\'");
            resultSet = statement.executeQuery(query);
            resultSet.next();
            if (Integer.parseInt(resultSet.getString(1))==0){//如果没有该条流水号
                result="找不到该流水号";
            }else if (Integer.parseInt(resultSet.getString(1))==2){//如果存在两条记录，则已经冲正
                result="该流水号已经冲正";
            }else {
                //获取原缴费记录的时间，金额等信息
                query=String.format("SELECT paydate ,deviceid from PAYFEE where bankserial=\'" + request.getParameter("bankserial")+"\'");
                resultSet = statement.executeQuery(query);
                resultSet.next();
                //如果冲正操作和缴费在同一天发生，则可以冲正
                if ((String.valueOf(resultSet.getDate(1))).equals(request.getParameter("reversetime"))){
                    if (resultSet.getString(2).equals(request.getParameter("deviceid"))){//调用存储过程进行冲正
                        CallableStatement callableStatement=connection.prepareCall("call chongzheng(?,?,?,?,?,?)");
                        callableStatement.setInt(1,Integer.parseInt(request.getParameter("deviceid")));
                        callableStatement.setString(2,banknumber);
                        callableStatement.setString(3,request.getParameter("bankserial"));
                        callableStatement.setDate(4,java.sql.Date.valueOf(request.getParameter("reversetime")));
                        callableStatement.setString(5,request.getParameter("reversenumber"));
                        callableStatement.registerOutParameter(6,Types.INTEGER);
                        callableStatement.execute();
                        int j=callableStatement.getInt(6);
                        if (j==1){//如果冲正成功
                            //查询冲正设备当前的欠费记录并且显示在jsp中
                            State=1;
                            result="  <table class='table table-hover table-striped' >" +
                                    "<caption><center>当前设备欠费信息汇总</center></caption>"+
                                    " <tbody> <th>设备ID</th><th>应缴费月份</th><th>基本费用</th>";
                            query=String.format("SELECT deviceid,yearmonth,basicfee FROM RECEIVABLES where flag='0' and deviceid=" +Integer.parseInt(request.getParameter("deviceid"))+"order by yearmonth");
                            resultSet = statement.executeQuery(query);
                            int count=0;
                            while (resultSet.next()){
                                count++;
                                result+="<tr><td>"+resultSet.getString(1)+"</td><td>"+resultSet.getString(2)+"</td><td>"+resultSet.getDouble(3)+"</td></tr>";
                                if (count>5){
                                    break;
                                }
                            }
                            result+="</table>";
                        }else {//调用存储过程失败，表示冲正金额错误
                            result = "冲正金额错误！！";
                        }
                        callableStatement.close();
                    }else {
                        result = "设备ID错误";
                    }

                }else{
                    result = "冲正日期已过！！";
                }
            }
                statement.close();
                connection.close();//关闭数据库连接
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
