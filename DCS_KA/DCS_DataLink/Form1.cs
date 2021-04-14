using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Net.Sockets;
using System.Net;
using System.Threading;
using Microsoft.Win32;
using System.Runtime.InteropServices;
using System.Configuration;
using System.CodeDom.Compiler;
using Microsoft.DirectX.DirectInput;


using System.Reflection;


namespace DCS_DataLink
{
    public partial class Form1 : Form
    {
        static Socket server_r;
        //接收socket
        static Socket server_s;
        //发送socket
        Thread t_r;
        //接收线程
        Thread t_s;
        //发送线程


        bool Connected = false;
        //是否连接DCS
        KeyboardHook k_hook = new KeyboardHook();
        //键盘钩子

        #region 画图用

        int width;
        int height;
        int subNum;
        float dx;
        Bitmap bp;
        Graphics g;
        Pen p = new Pen(Color.Black);

        #endregion

        /// <summary>
        /// 调节曲线编号，0==俯仰；1==滚转；2==油门
        /// </summary>
        int curveIndex;
        int[] curveInfo = new int[24];
        string[] curveKeyName = new string[24];
        bool curveAdjust = false;

        int pitchNeu = 0;
        int rollNeu = 0;
        int thrustNeu = 0;
        int selectNeu = 0;

        static int pitchAxis = 0;
        static int rollAxis = 0;
        static int thrustAxis = 0;

        int selectVAxis = 0;
        int selectHAxis = 0;

        float pitch;
        float roll;
        float thrust;

        float selectV;
        float selectH;

        int pitchInt;
        int rollInt;
        int thrustInt;

        int selectVInt;
        int selectHInt;

        int MaxPressTime1 = 1;
        //俯仰灵敏度
        float MaxCtrlPercentage1 = 1f;
        //控制限位器

        int MaxPressTime2 = 1;
        //滚转灵敏度
        float MaxCtrlPercentage2 = 1f;
        //控制限位器

        int MaxPressTime3 = 1;
        //油门灵敏度
        float MaxCtrlPercentage3 = 1f;
        //控制限位器

        int MaxPressTimeSelector = 1;

        int maxPressIndex = 2;
        //控制maxPressTime的比例


        int count = 0;
        //发送间隔用计数器

        static double currentSimTime = 0.0;
        //当前帧时间

        static double lastSimTime = -1.0;
        //上一帧时间

        static bool showMsg = false;
        //是否显示接收信息

        static float TAS = 0f;

        static bool initialTAS_Set = false;



        public static Form1 form1;

        int curveFormIndex = 0;
        //选择曲线类型
        
        bool setKey = false;
        //是否进入设置键位状态
        /// <summary>
        /// 当前设置键位编号1-6
        /// </summary>
        int setKeyIndex = 0;


        Device joystick;
        //摇杆对象

        bool joystickConnected = false;

        bool setJoystickButton = false;
        //是否进入摇杆键位设置
        /// <summary>
        /// 当前1-4对应上下左右
        /// </summary>
        int setButtonIndex = 0;

        #region AAR专用变量

        public static double[] transformFT = new double[7];
        public static double[] transformTK = new double[7];

        public static double[] lastTransformFT = new double[7];
        public static double[] lastTransformTK = new double[7];

        public static double[] velocityFT = new double[7];
        public static double[] velocityTK = new double[7];

        static double targetHeight = 5990.0;

        static double heightOffset = -10.0;

        static double distanceOffset = 20.0;

        static float pitchOffset = 0f;
        static float thrustOffset = 0f;

        //高度累计误差
        static double accumuErrorH = 0;
        //距离累计误差
        static double accumuErrorD = 0;

        static int waitCountH = 0;
        static int waitCountD = 0;

        static double speedErrorLast = 0;

        static bool enableAAR = false;

        #endregion

        public Form1()
        {

            InitializeComponent();
            Control.CheckForIllegalCrossThreadCalls = false;
            form1 = this;

        }
        /// <summary>
        /// 窗体加载
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void Form1_Load(object sender, EventArgs e)
        {
            
            k_hook.KeyDownEvent += new KeyEventHandler(hook_KeyDown);//钩住键按下
            k_hook.KeyUpEvent += new KeyEventHandler(hook_KeyUp);//勾住键抬起
            k_hook.Start();//安装键盘钩子

            width = pictureBox1.Width;
            height = pictureBox1.Height;
            subNum = 50;
            dx = (float)width / (float)subNum;

            bp = new Bitmap(width, height);
            g = Graphics.FromImage(bp);
            p = new Pen(Color.Black);

            curveKeyName[0] = "pitch";
            curveKeyName[1] = "roll";
            curveKeyName[2] = "thrust";
            curveKeyName[3] = "pitchNeu";
            curveKeyName[4] = "rollNeu";
            curveKeyName[5] = "thrustNeu";
            curveKeyName[6] = "maxTime1";
            curveKeyName[7] = "maxCtrl1";
            curveKeyName[8] = "pitchPKey";
            curveKeyName[9] = "pitchNKey";
            curveKeyName[10] = "rollPKey";
            curveKeyName[11] = "rollNKey";
            curveKeyName[12] = "thrustPKey";
            curveKeyName[13] = "thrustNKey";
            curveKeyName[14] = "maxTime2";
            curveKeyName[15] = "maxCtrl2";
            curveKeyName[16] = "maxTime3";
            curveKeyName[17] = "maxCtrl3";
            curveKeyName[18] = "SelectVPKey";
            curveKeyName[19] = "SelectVNKey";
            curveKeyName[20] = "SelectHPKey";
            curveKeyName[21] = "SelectHNKey";
            curveKeyName[22] = "maxTimeSelector";
            curveKeyName[23] = "selectorNeu";

            #region 初始化所有参数数据
            for (int i = 0; i < 24; i++)
            {
                curveInfo[i] = int.Parse(GetAppConfig(curveKeyName[i]));
            }
            #endregion

            #region 初始化读取归零设置选项
            if (curveInfo[3] == 0)
            {
                checkBox1.Checked = false;
            }
            else
            {
                checkBox1.Checked = true;
            }

            if (curveInfo[4] == 0)
            {
                checkBox2.Checked = false;
            }
            else
            {
                checkBox2.Checked = true;
            }

            if (curveInfo[5] == 0)
            {
                checkBox3.Checked = false;
            }
            else
            {
                checkBox3.Checked = true;
            }

            if (curveInfo[23] == 0)
            {
                checkBox4.Checked = false;
            }
            else
            {
                checkBox4.Checked = true;
            }
            #endregion

            trackBarSens1.Value = curveInfo[6];
            trackBarMaxCtrl1.Value = curveInfo[7];

            trackBarSens2.Value = curveInfo[14];
            trackBarMaxCtrl2.Value = curveInfo[15];

            trackBarSens3.Value = curveInfo[16];
            trackBarMaxCtrl3.Value = curveInfo[17];

            trackBarSelector.Value = curveInfo[22];


            timer1.Enabled = true;
        }


        private void button1_Click(object sender, EventArgs e)
        {
            //string ip = GetIpAddress();
            //textBox1.Text = ip;

            server_s = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            server_s.Bind(new IPEndPoint(IPAddress.Parse("127.0.0.1"), 12346));//绑定端口号和IP 
            server_s.ReceiveTimeout = 10;
            server_s.SendTimeout = 10;

            server_r = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            server_r.Bind(new IPEndPoint(IPAddress.Parse("127.0.0.1"), 12345));//绑定端口号和IP  
            server_r.ReceiveTimeout = 1000000;
            server_r.SendTimeout = 1000000;

            t_r = new Thread(ReciveMsg);//开启接收消息线程  
            t_r.Start();

            textBox1.Text = "连接已经开启";

            Connected = true;

        }

        static void SendMsg()
        {
            EndPoint point = new IPEndPoint(IPAddress.Parse("127.0.0.1"), 12344);
            while (true)
            {

            }


        }

        /// <summary>  
        /// 接收发送给本机ip对应端口号的数据报  
        /// </summary>  
        static void ReciveMsg()
        {
            while (true)
            {

                EndPoint point = new IPEndPoint(IPAddress.Any, 0);//用来保存发送方的ip和端口号  
                byte[] buffer = new byte[1024];
                
                int length = server_r.ReceiveFrom(buffer, ref point);//接收数据报  
                string message = Encoding.UTF8.GetString(buffer, 0, length);
                
                string head = message.Substring(0, 2);
                string body = message.Substring(2);

                string msgDisplay = "";

                if (head == "tm")
                {
                    currentSimTime = float.Parse(body);

                }
                else if (head == "va")
                {
                    TAS = float.Parse(body);

                    
                }
                else
                {
                    if (showMsg)
                    {
                        if (head == "ms")
                        {
                            msgDisplay = body+"\n";
                  
                            if (enableAAR)
                            {
                                string[] rawData = body.Split(';');
                                string[] FTData = rawData[0].Split(',');
                                string[] TKData = rawData[1].Split(',');

                                if (TKData.Length == 7)
                                {
                                    for (int i = 0; i < 7; i++)
                                    {
                                        transformFT[i] = double.Parse(FTData[i]);

                                        transformTK[i] = double.Parse(TKData[i]);

                                        //msgDisplay += transformFT[i].ToString() + "_" + transformTK[i].ToString() + "\n";
                                        //msgDisplay += velocityFT[i].ToString() + "_" + velocityTK[i].ToString() + "\n";
                                    }

                                    double deltaTime = transformFT[0] - lastTransformFT[0];

                                    for (int i = 0; i < 7; i++)
                                    {
                                        velocityFT[i] = (transformFT[i] - lastTransformFT[i]) / deltaTime;
                                        velocityTK[i] = (transformTK[i] - lastTransformTK[i]) / deltaTime;

                                        lastTransformFT[i] = transformFT[i];
                                        lastTransformTK[i] = transformTK[i];


                                    }
                                    #region 测试自动定高控制速度

                                    targetHeight = transformTK[2] + heightOffset;

                                    double heightError = -transformFT[2] + targetHeight;



                                    double speedError = Math.Sqrt(velocityTK[1] * velocityTK[1] + velocityTK[3] * velocityTK[3]) - Math.Sqrt(velocityFT[1] * velocityFT[1] + velocityFT[3] * velocityFT[3]);
                                    double acceleration = (speedError - speedErrorLast) / deltaTime;

                                    speedErrorLast = speedError;

                                    msgDisplay += "speedError:" + speedError.ToString() + "\n";

                                    double distance = Math.Sqrt(Math.Pow((transformTK[1] - transformFT[1]), 2) + Math.Pow((transformTK[3] - transformFT[3]), 2));

                                    double relativeP = velocityTK[1] * (transformFT[1] - transformTK[1]) + velocityTK[2] * (transformFT[2] - transformTK[2]) + velocityTK[3] * (transformFT[3] - transformTK[3]);

                                    if (waitCountH % 1000 == 0)
                                    {
                                        waitCountH = 0;
                                        accumuErrorH = 0;
                                    }
                                    if (waitCountD % 1000 == 0)
                                    {
                                        waitCountD = 0;
                                        accumuErrorD = 0;
                                    }
                                    accumuErrorH += heightError;
                                    accumuErrorD += speedError;

                                    waitCountH++;
                                    waitCountD++;

                                    //double targetVH = distance * 0.01 * Math.Sign(relativeP);

                                    //msgDisplay += targetVH.ToString() + "\n";

                                    //int pitchSign = Math.Sign(targetVV);

                                    float P1 = -(float)heightError / 500f;
                                    float I1 = (float)accumuErrorH / (waitCountH * 1000);
                                    float D1 = (float)velocityFT[2] / 100f;

                                    //float P2 = -(float)distance * Math.Sign(relativeP) / 5000f;
                                    //float I2 = (float)accumuErrorD / (waitCountH * 100000);
                                    //float D2 = (float)speedError / 100f;

                                    float P2 = (float)speedError;
                                    float I2 = (float)accumuErrorD / (waitCountD);
                                    float D2 = (float)acceleration;

                                    msgDisplay += "p1: " + P1.ToString() + "\n";
                                    msgDisplay += "i1: " + I1.ToString() + "\n";
                                    msgDisplay += "d1: " + D1.ToString() + "\n";

                                    msgDisplay += "p2: " + P2.ToString() + "\n";
                                    msgDisplay += "i2: " + I2.ToString() + "\n";
                                    msgDisplay += "d2: " + D2.ToString() + "\n";


                                    pitchOffset = P1 + I1 + D1;

                                    if (P2 + 8f * (D2) > 0)
                                    {
                                        if (Math.Abs(D2) < 1f || P2 * D2 > 0)
                                        {
                                            thrustOffset += 0.002f * Math.Abs(D2);
                                        }

                                    }
                                    else
                                    {
                                        if (Math.Abs(D2) < 1f || P2 * D2 > 0)
                                        {
                                            thrustOffset -= 0.002f * Math.Abs(D2);
                                        }
                                    }




                                    if (Math.Abs(pitchOffset) > 1)
                                    {
                                        pitchOffset = Math.Sign(pitchOffset);

                                    }
                                    if (Math.Abs(thrustOffset) > 1)
                                    {
                                        thrustOffset = Math.Sign(thrustOffset);
                                    }
                                }
                                
                            }
                            else
                            {
                                pitchOffset = 0;
                                thrustOffset = 0;
                            }


                            //+ (float)accumuError / ((float)accumuTime * 1000)
                            //if (velocityFT[2] >= targetVV)
                            //{
                            //    //pitchAxis = 5;
                            //    pitchOffset = (float)Math.Sqrt(Math.Abs(heightError)) / 100f + (float)velocityFT[2] / 100;
                            //}
                            //else
                            //{
                            //    pitchOffset = -(float)Math.Sqrt(Math.Abs(heightError)) / 100f + (float)velocityFT[2] / 100;
                            //}
                            //waitCount++;

                            //if (waitCount % 10 == 0)
                            //{
                            //    if (speedError >= targetVH)
                            //    {

                            //        //thrustAxis += 1;

                            //        thrustAxis += (int)(speedError - targetVH) / 2;


                            //    }
                            //    else
                            //    {

                            //        thrustAxis += (int)(speedError - targetVH) / 2;

                            //    }
                            //    waitCount = 0;
                            //}




                            ////else
                            ////{
                            ////    pitchAxis = -pitchSign * 1;
                            ////}
                            //if (Math.Abs(targetVH) >= Math.Abs(velocityFT[1]))
                            //{
                            //    pitchAxis = pitchSign * 3;

                            //}
                            //else
                            //{
                            //    pitchAxis = -pitchSign * 1;
                            //}



                            #endregion

                        }

                        form1.richTextBox1.Text = msgDisplay;
                    }
                    if (message == "quit")
                    {
                        initialTAS_Set = false;
                        pitchAxis = 0;
                        rollAxis = 0;
                        thrustAxis = 0;
                        form1.richTextBox1.Text = "DCS已退出，注意关闭遥控程序";

                    }
                }


                //Thread.Sleep(100);
            }
            
        }
        /// <summary>
        /// 摇杆连接用
        /// </summary>
        void InitDevices()
        {

            //create joystick device.
            foreach (
                DeviceInstance di in
                Manager.GetDevices(
                    DeviceClass.GameControl,
                    EnumDevicesFlags.AttachedOnly))
            {
                joystick = new Device(di.InstanceGuid);
                break;
            }

            if (joystick == null)
            {
                //Throw exception if joystick not found.
                //throw new Exception("No joystick found.");
                textBoxJoystick.Text = "No joystick found.";
            }
            else
            {
                joystickConnected = true;
            }
            foreach (DeviceObjectInstance doi in joystick.Objects)
            {
                if ((doi.ObjectId & (int)DeviceObjectTypeFlags.Axis) != 0)
                {
                    joystick.Properties.SetRange(
                        ParameterHow.ById,
                        doi.ObjectId,
                        new InputRange(-1000, 1000));
                }

            }
            textBoxJoystick.Text = joystick.Properties.ProductName;

            

            //Set joystick axis mode absolute.
            joystick.Properties.AxisModeAbsolute = true;

            //set cooperative level.


            joystick.SetCooperativeLevel(
                this,
                CooperativeLevelFlags.NonExclusive |
                CooperativeLevelFlags.Background);

            //Acquire devices for capturing.

            joystick.Acquire();

        }

        private void button2_Click(object sender, EventArgs e)
        {
            //t_r.Abort();
            //t_s.Abort();
            //server_r.Close();
            server_s.Close();
            textBox1.Text = "连接关闭";
            //timer1.Enabled = false;
            Connected = false;

            t_r.Abort();
            server_r.Close();

            initialTAS_Set = false;

        }

        private string GetIpAddress()
        {
            string hostName = Dns.GetHostName();  //获取本机名
            IPHostEntry localhost = Dns.GetHostEntry(hostName); //方法已过期，可以获取IPv4的地址
            //IPHostEntry localhost = Dns.GetHostEntry(hostName);   //获取IPv6地址
            IPAddress localaddr = localhost.AddressList[0];

            return localaddr.ToString();
        }



        private void hook_KeyDown(object sender, KeyEventArgs e)
        {

            //if (e.KeyValue == (int)Keys.Up)
            //{
            //    pitchAxis += 1;
            //}
            //else if(e.KeyValue == (int)Keys.Down)
            //{
            //    pitchAxis -= 1;
            //}
            //if(e.KeyValue == (int)Keys.Left)
            //{
            //    rollAxis += 1;
            //}
            //if (e.KeyValue == (int)Keys.Right)
            //{
            //    rollAxis -= 1;
            //}
            //if (e.KeyValue == (int)Keys.PageUp)
            //{
            //    thrustAxis += 1;
            //}
            //if (e.KeyValue == (int)Keys.PageDown)
            //{
            //    thrustAxis -= 1;
            //}

            if (setKey)
            {
                switch (setKeyIndex)
                {
                    case 1:
                        curveInfo[8] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[8], e.KeyValue.ToString());
                        PitchKeyPButton.Text = e.KeyCode.ToString();                       
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    case 2:
                        curveInfo[9] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[9], e.KeyValue.ToString());
                        PitchKeyNButton.Text = e.KeyCode.ToString();
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    case 3:
                        curveInfo[10] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[10], e.KeyValue.ToString());
                        RollKeyPButton.Text = e.KeyCode.ToString();
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    case 4:
                        curveInfo[11] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[11], e.KeyValue.ToString());
                        RollKeyNButton.Text = e.KeyCode.ToString();
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    case 5:
                        curveInfo[12] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[12], e.KeyValue.ToString());
                        ThrustKeyPButton.Text = e.KeyCode.ToString();
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    case 6:
                        curveInfo[13] = e.KeyValue;
                        UpdateAppConfig(curveKeyName[13], e.KeyValue.ToString());
                        ThrustKeyNButton.Text = e.KeyCode.ToString();
                        setKey = false;
                        setKeyIndex = 0;
                        break;
                    default:
                        break;
                }
            }

        }
        private void hook_KeyUp(object sender, KeyEventArgs e)
        {

            //if ((e.KeyValue == (int)Keys.Up || e.KeyValue == (int)Keys.Down) && Connected && pitchNeu == 1)
            //{
            //    pitchAxis = 0;
            //}
            //if ((e.KeyValue == (int)Keys.Left || e.KeyValue == (int)Keys.Right) && Connected && rollNeu == 1)
            //{
            //    rollAxis = 0;
            //}
            //if ((e.KeyValue == (int)Keys.PageUp || e.KeyValue == (int)Keys.PageDown) && Connected && thrustNeu == 1)
            //{
            //    thrustAxis = 0;
            //}

            if ((e.KeyValue == curveInfo[8]|| e.KeyValue == curveInfo[9]) && Connected && pitchNeu == 1)
            {
                pitchAxis = 0;
            }
            if ((e.KeyValue == curveInfo[10] || e.KeyValue == curveInfo[11]) && Connected && rollNeu == 1)
            {
                rollAxis = 0;
            }
            if ((e.KeyValue == curveInfo[12] || e.KeyValue == curveInfo[13]) && Connected && thrustNeu == 1)
            {
                thrustAxis = 0;
            }

        }

        private void UpdateJoystickButtonSettings()
        {
            JoystickState state = joystick.CurrentJoystickState;

            //Capture Buttons.
            string msg="";
            byte[] buttons = state.GetButtons();
            for (int i = 0; i < buttons.Length; i++)
            {
                if (buttons[i] != 0)
                {
                    msg += buttons[i].ToString()+"/";
                    switch (setButtonIndex)
                    {
                        case 1:
                            curveInfo[18] = i;
                            UpdateAppConfig(curveKeyName[18], i.ToString());
                            buttonSelectUp.Text = "button" + i.ToString();
                            setButtonIndex = 0;
                            setJoystickButton = false;
                            break;
                        case 2:
                            curveInfo[19] = i;
                            UpdateAppConfig(curveKeyName[19], i.ToString());
                            buttonSelectDown.Text = "button" + i.ToString();
                            setButtonIndex = 0;
                            setJoystickButton = false;
                            break;
                        case 3:
                            curveInfo[20] = i;
                            UpdateAppConfig(curveKeyName[20], i.ToString());
                            buttonSelectLeft.Text = "button" + i.ToString();
                            setButtonIndex = 0;
                            setJoystickButton = false;
                            break;
                        case 4:
                            curveInfo[21] = i;
                            UpdateAppConfig(curveKeyName[21], i.ToString());
                            buttonSelectRight.Text = "button" + i.ToString();
                            setButtonIndex = 0;
                            setJoystickButton = false;
                            break;
                        default:
                            break;
                    }
                    break;
                }
            }


            //textBox1.Text = info;
            //textBox2.Text = Time_Record.TotalSeconds.ToString();
        }


        public void TestDraw()
        {
            Bitmap bp = new Bitmap(300, 150);
            Graphics g = Graphics.FromImage(bp);
            g.Clear(Color.White);
            Random r = new Random();
            for (int i = 0; i < 25; i++)
            {

                int r1 = r.Next(bp.Width);
                int r2 = r.Next(bp.Width);
                int h1 = r.Next(bp.Height);
                int h2 = r.Next(bp.Height);
                Pen p = new Pen(Color.Silver);
                g.DrawLine(p, r1, h1, r2, h2);

            }
            pictureBox1.Image = (Image)bp;
        }

        private void button4_Click(object sender, EventArgs e)
        {
            //server_r = new Socket(AddressFamily.InterNetwork, SocketType.Dgram, ProtocolType.Udp);
            //server_r.Bind(new IPEndPoint(IPAddress.Parse("127.0.0.1"), 12345));//绑定端口号和IP  
            //server_r.ReceiveTimeout = 1000000;
            //server_r.SendTimeout = 1000000;

            //t_r = new Thread(ReciveMsg);//开启接收消息线程  
            //t_r.Start();
            showMsg = true;

        }

        private void button5_Click(object sender, EventArgs e)
        {
            //t_r.Abort();
            //server_r.Close();
            showMsg = false;
        }

        private void button6_Click(object sender, EventArgs e)
        {
            
        }
        /// <summary>
        /// 每帧计算内容
        /// </summary>
        /// <param name="sender"></param>
        /// <param name="e"></param>
        private void timer1_Tick(object sender, EventArgs e)
        {

            #region 滑块显示与数据更新
            int tmp = (trackBar1.Value - 50) * 2;
            textBoxTrackBar.Text = tmp.ToString();

            //实时设置俯仰行程与限位
            float tmp2 = trackBarSens1.Value * 0.02f* maxPressIndex;
            textBoxMaxTime1.Text = tmp2.ToString();

            float tmp3 = trackBarMaxCtrl1.Value * 0.01f;
            textBoxMaxCtrl1.Text = tmp3.ToString();

            MaxPressTime1 = curveInfo[6] * maxPressIndex;
            MaxCtrlPercentage1 = tmp3;

            //实时设置滚转行程与限位
            tmp2 = trackBarSens2.Value * 0.02f * maxPressIndex;
            textBoxMaxTime2.Text = tmp2.ToString();

            tmp3 = trackBarMaxCtrl2.Value * 0.01f;
            textBoxMaxCtrl2.Text = tmp3.ToString();

            MaxPressTime2 = curveInfo[14] * maxPressIndex;
            MaxCtrlPercentage2 = tmp3;


            //实时设置油门行程与限位
            tmp2 = trackBarSens3.Value * 0.02f * maxPressIndex;
            textBoxMaxTime3.Text = tmp2.ToString();

            tmp3 = trackBarMaxCtrl3.Value * 0.01f;
            textBoxMaxCtrl3.Text = tmp3.ToString();

            MaxPressTime3 = curveInfo[16] * maxPressIndex;
            MaxCtrlPercentage3 = tmp3;

            //实时设置目标指示器行程
            tmp2 = trackBarSelector.Value * 0.02f*maxPressIndex; ;
            textBoxSelector.Text = tmp2.ToString();

            MaxPressTimeSelector = curveInfo[22] * maxPressIndex;

            #endregion


            if (lastSimTime != currentSimTime)
            {
                AxisSynchro();
                if (joystickConnected)
                {
                    SelectorSynchro();
                }


                if (Connected)
                {

                    #region 处理初始状态油门问题
                    if (!initialTAS_Set && TAS<50)
                    {
                        thrustAxis = -curveInfo[6] * maxPressIndex;
                        initialTAS_Set = true;
                    }
                    if(!initialTAS_Set && TAS > 50)
                    {
                        thrustAxis = 0;
                        initialTAS_Set = true;
                    }
                    #endregion


                    EndPoint point = new IPEndPoint(IPAddress.Parse("127.0.0.1"), 12344);

 

                    if (Math.Abs(pitchAxis) > MaxPressTime1)
                    {
                        pitchAxis = Math.Sign(pitchAxis) * MaxPressTime1;
                    }
                    if (Math.Abs(rollAxis) > MaxPressTime2)
                    {
                        rollAxis = Math.Sign(rollAxis) * MaxPressTime2;
                    }
                    if (Math.Abs(thrustAxis) > MaxPressTime3)
                    {
                        thrustAxis = Math.Sign(thrustAxis) * MaxPressTime3;
                    }

                    if (Math.Abs(selectVAxis) > MaxPressTimeSelector)
                    {
                        selectVAxis = Math.Sign(selectVAxis) * MaxPressTimeSelector;
                    }
                    if (Math.Abs(selectHAxis) > MaxPressTimeSelector)
                    {
                        selectHAxis = Math.Sign(selectHAxis) * MaxPressTimeSelector;
                    }

                    pitch = (float)pitchAxis / (float)MaxPressTime1+pitchOffset;
                    roll = (float)rollAxis / (float)MaxPressTime2;
                    thrust = (float)thrustAxis / (float)MaxPressTime3+thrustOffset;
                    selectV = (float)selectVAxis / (float)MaxPressTimeSelector;
                    selectH = (float)selectHAxis / (float)MaxPressTimeSelector;

                    pitch = -UpdateAxis(0, pitch) * (1000 * MaxCtrlPercentage1);
                    roll = -UpdateAxis(1, roll) * (1000 * MaxCtrlPercentage2);
                    thrust = -UpdateAxis(2, thrust) * (1000 * MaxCtrlPercentage3);
                    selectV = 1000f * selectV;
                    selectH = -1000f * selectH;

                    pitchInt = (int)pitch;
                    rollInt = (int)roll;
                    thrustInt = (int)thrust;
                    selectVInt = (int)selectV;
                    selectHInt = (int)selectH;


                    textBoxPitch.Text = pitchInt.ToString();
                    textBoxRoll.Text = rollInt.ToString();
                    textBoxThrust.Text = thrustInt.ToString();
                    textBoxSV.Text = selectVInt.ToString();
                    textBoxSH.Text = selectHInt.ToString();



                    if (count > 0 && count % 1 == 0)
                    {
                        count = 0;

                        if (pitchInt >= 0)
                        {
                            pitchInt += 20000;
                        }
                        else
                        {
                            pitchInt = 10000 - pitchInt;
                        }

                        if (rollInt >= 0)
                        {
                            rollInt += 20000;
                        }
                        else
                        {
                            rollInt = 10000 - rollInt;
                        }

                        if (thrustInt >= 0)
                        {
                            thrustInt += 20000;
                        }
                        else
                        {
                            thrustInt = 10000 - thrustInt;
                        }

                        if (selectVInt >= 0)
                        {
                            selectVInt += 20000;
                        }
                        else
                        {
                            selectVInt = 10000 - selectVInt;
                        }

                        if (selectHInt >= 0)
                        {
                            selectHInt += 20000;
                        }
                        else
                        {
                            selectHInt = 10000 - selectHInt;
                        }

                        if (!joystickConnected)
                        {
                            server_s.SendTo(Encoding.UTF8.GetBytes(pitchInt.ToString() + rollInt.ToString() + thrustInt.ToString()+"0000000000"), point);
                        }
                        else
                        {
                            server_s.SendTo(Encoding.UTF8.GetBytes("000000000000000"+selectVInt.ToString()+selectHInt.ToString()), point);
                        }
                        
                        //server_s.SendTo(Encoding.UTF8.GetBytes(pitchInt.ToString() + rollInt.ToString() + thrustInt.ToString()), point);

                        //server_s.SendTo(Encoding.UTF8.GetBytes(msg), point);
                        //msg = "rll" + rollInt.ToString();
                        //server_s.SendTo(Encoding.UTF8.GetBytes(msg), point);
                        //msg = "thr" + thrustInt.ToString();
                        //server_s.SendTo(Encoding.UTF8.GetBytes(msg), point);
                    }
                    count++;
                }

                lastSimTime = currentSimTime;



            }
            



            //更新曲线设置
            if (curveAdjust)
            {
                if(trackBar1.Value != curveInfo[curveIndex])
                {
                    UpdateAppConfig(curveKeyName[curveIndex], trackBar1.Value.ToString());
                    curveInfo[curveIndex] = trackBar1.Value;
                }

                #region 绘制曲线
                g.Clear(Color.White);

                p = new Pen(Color.Black);
                g.DrawLine(p, 0f, height / 2f, width * 1f, width / 2f);
                g.DrawLine(p, width / 2f, 0f, width / 2f, height * 1f);

                for (int i = 0; i < subNum; i++)
                {
                    p = new Pen(Color.Red);
                    float x1 = i * dx * 2f / width - 1f;
                    float x2 = (i + 1) * dx * 2f / width - 1f;
                    float y1 = 0;
                    float y2 = 0;
                    float temp = ((float)trackBar1.Value - 50f) / 50f;

                    if(curveFormIndex == 0)
                    {
                        if (temp >= 0)
                        {
                            temp = (float)Math.Pow(10, temp);


                            if (x1 >= 0)
                            {
                                y1 = (1 - (float)Math.Pow(x1, temp)) * height / 2f;
                                y2 = (1 - (float)Math.Pow(x2, temp)) * height / 2f;
                            }
                            else
                            {
                                y1 = (1 + (float)Math.Pow(-x1, temp)) * height / 2f;
                                y2 = (1 + (float)Math.Pow(-x2, temp)) * height / 2f;
                            }
                        }
                        else
                        {
                            temp = (float)Math.Pow(10, -temp);

                            if (x1 >= 0)
                            {
                                y1 = ((float)Math.Pow((1 - x1), temp)) * height / 2f;
                                y2 = ((float)Math.Pow((1 - x2), temp)) * height / 2f;
                            }
                            else
                            {
                                y1 = (2 - (float)Math.Pow((1 + x1), temp)) * height / 2f;
                                y2 = (2 - (float)Math.Pow((1 + x2), temp)) * height / 2f;
                            }

                        }
                    }
                    else
                    {
                        if (temp >= 0)
                        {
                            temp = (float)Math.Pow(1 - temp, 3);

                            if (x1 >= 0)
                            {
                                y1 = (1 - x1 * temp / (x1 * temp - x1 + 1)) * height / 2f;
                                y2 = (1 - x2 * temp / (x2 * temp - x2 + 1)) * height / 2f;
                            }
                            else
                            {
                                y1 = (1 - x1 * temp / (-x1 * temp + x1 + 1)) * height / 2f;
                                y2 = (1 - x2 * temp / (-x2 * temp + x2 + 1)) * height / 2f;

                            }


                        }
                        else
                        {
                            temp = (float)Math.Pow(1 + temp, 3);


                            if (x1 >= 0)
                            {
                                y1 = ((1 - x1) * temp / ((1 - x1) * temp - (1 - x1) + 1)) * height / 2f;
                                y2 = ((1 - x2) * temp / ((1 - x2) * temp - (1 - x2) + 1)) * height / 2f;
                            }
                            else
                            {
                                y1 = (2 - ((1 + x1) * temp / ((1 + x1) * temp - (1 + x1) + 1))) * height / 2f;
                                y2 = (2 - ((1 + x2) * temp / ((1 + x2) * temp - (1 + x2) + 1))) * height / 2f;
                            }

                        }
                    }


                if (Math.Abs(y1) > height - 1)
                    {
                        y1 = (height - 1) * Math.Sign(y1);
                    }
                    if (Math.Abs(y2) > height - 1)
                    {
                        y2 = (height - 1) * Math.Sign(y2);
                    }

                    g.DrawLine(p, (x1 + 1) * width / 2f, y1, (x2 + 1) * width / 2f, y2);
                }
                pictureBox1.Image = (Image)bp;

                #endregion
            }


            #region 更新归零选项
            if (checkBox1.Checked == true)
            {
                pitchNeu = 1;
            }
            else
            {
                pitchNeu = 0;
            }

            if (checkBox2.Checked == true)
            {
                rollNeu = 1;
            }
            else
            {
                rollNeu = 0;
            }

            if (checkBox3.Checked == true)
            {
                thrustNeu = 1;
            }
            else
            {
                thrustNeu = 0;
            }

            if (checkBox4.Checked == true)
            {
                selectNeu = 1;
            }
            else
            {
                selectNeu = 0;
            }

            if(pitchNeu != curveInfo[3])
            {
                curveInfo[3] = pitchNeu;
                UpdateAppConfig(curveKeyName[3], pitchNeu.ToString());
            }
            if (rollNeu != curveInfo[4])
            {
                curveInfo[4] = rollNeu;
                UpdateAppConfig(curveKeyName[4], rollNeu.ToString());
            }
            if (thrustNeu != curveInfo[5])
            {
                curveInfo[5] = thrustNeu;
                UpdateAppConfig(curveKeyName[5], thrustNeu.ToString());
            }
            if (selectNeu != curveInfo[23])
            {
                curveInfo[23] = selectNeu;
                UpdateAppConfig(curveKeyName[23], selectNeu.ToString());
            }
            #endregion

            #region TrackBar动态调节

            if (trackBarSens1.Value != curveInfo[6])
            {
                curveInfo[6] = trackBarSens1.Value;
                UpdateAppConfig(curveKeyName[6], trackBarSens1.Value.ToString());
                
            }
            if (trackBarMaxCtrl1.Value != curveInfo[7])
            {
                curveInfo[7] = trackBarMaxCtrl1.Value;
                UpdateAppConfig(curveKeyName[7], trackBarMaxCtrl1.Value.ToString());

            }

            if (trackBarSens2.Value != curveInfo[14])
            {
                curveInfo[14] = trackBarSens2.Value;
                UpdateAppConfig(curveKeyName[14], trackBarSens2.Value.ToString());

            }
            if (trackBarMaxCtrl2.Value != curveInfo[15])
            {
                curveInfo[15] = trackBarMaxCtrl2.Value;
                UpdateAppConfig(curveKeyName[15], trackBarMaxCtrl2.Value.ToString());

            }

            if (trackBarSens3.Value != curveInfo[16])
            {
                curveInfo[16] = trackBarSens3.Value;
                UpdateAppConfig(curveKeyName[16], trackBarSens3.Value.ToString());

            }
            if (trackBarMaxCtrl3.Value != curveInfo[17])
            {
                curveInfo[17] = trackBarMaxCtrl3.Value;
                UpdateAppConfig(curveKeyName[17], trackBarMaxCtrl3.Value.ToString());

            }
            if (trackBarSelector.Value != curveInfo[22])
            {
                curveInfo[22] = trackBarSelector.Value;
                UpdateAppConfig(curveKeyName[22], trackBarSelector.Value.ToString());

            }
            #endregion

            #region 设置摇杆按键
            if (setJoystickButton)
            {
                UpdateJoystickButtonSettings();
            }
            #endregion

        }

        //俯仰曲线调节激活
        private void button6_Click_1(object sender, EventArgs e)
        {
            curveIndex = 0;
            //form1.timer1.Enabled = true;
            curveAdjust = true;
            trackBar1.Value = curveInfo[curveIndex];
        }
        //滚转曲线调节激活
        private void button7_Click(object sender, EventArgs e)
        {
            curveIndex = 1;
            //form1.timer1.Enabled = true;
            curveAdjust = true;
            trackBar1.Value = curveInfo[curveIndex];
        }
        //油门曲线调节激活
        private void button8_Click(object sender, EventArgs e)
        {
            curveIndex = 2;
            //form1.timer1.Enabled = true;
            curveAdjust = true;
            trackBar1.Value = curveInfo[curveIndex];
        }

        ///<summary> 
        ///返回*.exe.config文件中appSettings配置节的value项  
        ///</summary> 
        ///<param name="strKey"></param> 
        ///<returns></returns> 
        public static string GetAppConfig(string strKey)
        {
            string file = System.Windows.Forms.Application.ExecutablePath;
            Configuration config = ConfigurationManager.OpenExeConfiguration(file);
            foreach (string key in config.AppSettings.Settings.AllKeys)
            {
                if (key == strKey)
                {
                    return config.AppSettings.Settings[strKey].Value.ToString();
                }
            }
            return null;
        }

        ///<summary>  
        ///在*.exe.config文件中appSettings配置节Value值 
        ///</summary>  
        ///<param name="Key"></param>  
        ///<param name="newValue"></param>  
        public static void UpdateAppConfig(string Key, string newValue)
        {
            string file = System.Windows.Forms.Application.ExecutablePath;
            Configuration config = ConfigurationManager.OpenExeConfiguration(file);
            //bool exist = false;
            foreach (string key in config.AppSettings.Settings.AllKeys)
            {
                if (key == Key)
                {
                    config.AppSettings.Settings[Key].Value = newValue;
                }
            }
            //if (exist)
            //{
            //    config.AppSettings.Settings.Remove(Key);
            //}
            //config.AppSettings.Settings.Add(Key, newValue);
            config.Save(ConfigurationSaveMode.Modified);
            ConfigurationManager.RefreshSection("appSettings");
        }

        //计算三轴经过曲线后的值
        public float UpdateAxis(int index,float input)
        {
            float output = 0f;
            float temp = ((float)curveInfo[index] - 50f) / 50f;
            if(curveFormIndex == 0)
            {
                if (temp >= 0)
                {
                    temp = (float)Math.Pow(10, temp);

                    if (input >= 0)
                    {
                        output = (float)Math.Pow(input, temp);
                    }
                    else
                    {
                        output = -(float)Math.Pow(-input, temp);

                    }
                }
                else
                {
                    temp = (float)Math.Pow(10, -temp);

                    if (input >= 0)
                    {
                        output = 1 - (float)Math.Pow(1 - input, temp);
                    }
                    else
                    {
                        output = -1 + (float)Math.Pow(1 + input, temp);
                    }

                }
            }
            else
            {
                if (temp >= 0)
                {
                    temp = (float)Math.Pow(1 - temp, 3);

                    if (input >= 0)
                    {
                        output = (float)input * temp / (input * temp - input + 1);
                    }
                    else
                    {
                        output = (float)input * temp / (-input * temp + input + 1);

                    }
                }
                else
                {
                    temp = (float)Math.Pow(1 + temp, 3);

                    if (input >= 0)
                    {
                        output = 1 - (float)(1 - input) * temp / ((1 - input) * temp - (1 - input) + 1);
                    }
                    else
                    {
                        output = -1 + (float)(1 + input) * temp / ((1 + input) * temp - (1 + input) + 1);
                    }

                }
            }

            return output;
        }

        //按键检测与三轴增量累计
        public void AxisSynchro()
        {
            #region 老方法
            //if (k_hook.ctrlKeyDown[0])
            //{
            //    pitchAxis += 1;
            //}
            //if (k_hook.ctrlKeyDown[1])
            //{
            //    pitchAxis -= 1;
            //}
            //if (k_hook.ctrlKeyDown[2])
            //{
            //    rollAxis += 1;
            //}
            //if (k_hook.ctrlKeyDown[3])
            //{
            //    rollAxis -= 1;
            //}
            //if (k_hook.ctrlKeyDown[4])
            //{
            //    thrustAxis += 1;
            //}
            //if (k_hook.ctrlKeyDown[5])
            //{
            //    thrustAxis -= 1;
            //}
            #endregion

            if (k_hook.keyDown[curveInfo[8]])
            {
                pitchAxis += 1;
            }
            if (k_hook.keyDown[curveInfo[9]])
            {
                pitchAxis -= 1;
            }
            if (k_hook.keyDown[curveInfo[10]])
            {
                rollAxis += 1;
            }
            if (k_hook.keyDown[curveInfo[11]])
            {
                rollAxis -= 1;
            }
            if (k_hook.keyDown[curveInfo[12]])
            {
                thrustAxis += 1;
            }
            if (k_hook.keyDown[curveInfo[13]])
            {
                thrustAxis -= 1;
            }
        }

        public void SelectorSynchro()
        {
            JoystickState state = joystick.CurrentJoystickState;

            //Capture Buttons.

            byte[] buttons = state.GetButtons();

            int countVPressed = 0;
            int countHPressed = 0;

            for (int i = 0; i < buttons.Length; i++)
            {
                if (buttons[i] != 0)
                {
                    if (i == curveInfo[18])
                    {
                        selectVAxis += 1;
                        countVPressed++;

                    }
                    else if (i == curveInfo[19])
                    {
                        selectVAxis -= 1;
                        countVPressed++;
                    }
                    else if (i == curveInfo[20])
                    {
                        selectHAxis += 1;
                        countHPressed++;
                    }
                    else if (i == curveInfo[21])
                    {
                        selectHAxis -= 1;
                        countHPressed++;
                    }
                    else
                    {
                        continue;
                    }
                }

            }
            //还差归零
            if(countVPressed==0 && selectNeu==1)
            {
                selectVAxis = 0;
            }
            if (countHPressed == 0 && selectNeu == 1)
            {
                selectHAxis = 0;
            }
        }

        private void button3_Click(object sender, EventArgs e)
        {
            if(curveFormIndex == 0)
            {
                curveFormIndex = 1;
            }
            else
            {
                curveFormIndex = 0;
            }
        }



        private void PitchKeyPButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 1;
        }
        private void PitchKeyNButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 2;
        }

        private void RollKeyPButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 3;
        }
        private void RollKeyNButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 4;
        }

        private void ThrustKeyPButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 5;
        }
        private void ThrustKeyNButton_Click(object sender, EventArgs e)
        {
            setKey = true;
            setKeyIndex = 6;
        }

        //连接摇杆
        private void button9_Click(object sender, EventArgs e)
        {
            InitDevices();
            
        }

        private void button10_Click(object sender, EventArgs e)
        {
            joystickConnected = false;

            textBoxJoystick.Text = "摇杆控制被覆盖";
        }

        private void buttonSelectUp_Click(object sender, EventArgs e)
        {
            if (joystickConnected)
            {
                setJoystickButton = true;
                setButtonIndex = 1;
            }

        }

        private void buttonSelectDown_Click(object sender, EventArgs e)
        {
            if (joystickConnected)
            {
                setJoystickButton = true;
                setButtonIndex = 2;
            }
        }

        private void buttonSelectLeft_Click(object sender, EventArgs e)
        {
            if (joystickConnected)
            {
                setJoystickButton = true;
                setButtonIndex = 3;
            }
        }

        private void buttonSelectRight_Click(object sender, EventArgs e)
        {
            if (joystickConnected)
            {
                setJoystickButton = true;
                setButtonIndex = 4;
            }
        }

        private void button11_Click(object sender, EventArgs e)
        {
            enableAAR =!enableAAR;
            if (enableAAR)
            {
                button11.Text = "关闭AAR辅助";
            }
            else
            {
                button11.Text = "打开AAR辅助";
            }

        }
    }
}
