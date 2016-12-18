/**
 * Created by Administrator on 2016/11/19.
 */
//这个javascript里所用的方法都是利用ajax向servlet提交一个request，对返回的结果进行处理

function query() {//执行查询
    $.ajax({
        cache: false,
        type: "POST",
        url: 'Servlet/Query',
        data: $('#query').serialize(),
        async: true,
        dataType: "json",
        error: function (msg) {
            alert("查询失败");
        },
        success: function (msg) {
            var info = eval(msg).message;
            alert(info);
        }
    });
}
function querydetail() {//查询细节
    $.ajax({
        cache: false,
        type: "POST",
        url: 'Servlet/Querydetail',
        data: $('#querydetail').serialize(),
        async: true,
        dataType: "json",
        error: function (msg) {
            alert("查询失败");
        },
        success: function (msg) {
            var info = eval(msg).message;
            alert(info);
        }
    });
}
function pay() {//缴费
    $.ajax({
        cache: false,
        type: "POST",
        url: 'Servlet/Pay',
        data: $('#pay').serialize(),
        async: true,
        dataType: "json",
        error: function (msg) {
            alert("缴费失败");
        },
        success: function (msg) {
            var state = eval(msg).find;
            if(state==true){//返回状态为true，表示缴费成功，servlet返回一段html代码，ajax将其显示在指定位置
                var info=eval(msg).message;
                var table=document.getElementById("unpay");
                table.innerHTML=info;
            }else {
                alert("输入信息有误，请重新输入")
            }
        }
    });
}

function reverse(){//冲正
    $.ajax({
        cache: false,
        type: "POST",
        url: 'Servlet/Reverse',
        data: $('#reverse').serialize(),
        async: true,
        dataType: "json",
        error: function (msg) {
            alert("冲正失败");
        },
        success: function (msg) {
            var state = eval(msg).find;
            if(state==true){//返回状态为true，表示冲正成功，servlet返回一段html代码，ajax将其显示在指定位置
                var info=eval(msg).message;
                var table=document.getElementById("reverseresult");
                table.innerHTML=info;
            }else {
                alert(eval(msg).message);
            }
        }
    });
}
function check(){//对账
    $.ajax({
        cache: false,
        type: "POST",
        url: 'Servlet/Check',
        data: $('#check').serialize(),
        async: true,
        dataType: "json",
        error: function (msg) {
            alert("对账失败");
        },
        success: function (msg) {
            var state = eval(msg).find;
            if(state==true){
                alert("账单正确");
            }else {//返回状态为false，表示对账异常，servlet返回一段html代码，ajax将其显示在指定位置
                var info=eval(msg).message;
                var table=document.getElementById("checkdetail");
                table.innerHTML=info;
            }
        }
    });
}
