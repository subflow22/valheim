#!/bin/bash

#upgrades and prerequisites
echo "upgrades" >> /var/log/userdata 2>&1
yum upgrade -y -q
yum install -y amazon-efs-utils \
			glibc.i686 \
			glibc.x86_64 \
			libgcc_s.so.1 \
			SDL2.i686 \
			SDL2.x86_64 >> /var/log/userdata 2>&1

#aws cloudwatch agent - it is expensive $$$

echo "cwa setup" >> /var/log/userdata 2>&1
cwl_path=/opt/aws/amazon-cloudwatch-agent 

systemctl restart amazon-cloudwatch-agent && systemctl enable amazon-cloudwatch-agent
sleep 5
systemctl stop amazon-cloudwatch-agent
sleep 5
cat <<"EOF" > $cwl_path/amazon-cloudwatch-agent.json
${TEMPLATE_FILE}
EOF

echo "cwa copy config" >> /var/log/userdata 2>&1
rm -f $cwl_path/etc/amazon-cloudwatch-agent.d/default
rm -f $cwl_path/etc/amazon-cloudwatch-agent.json
cp -f $cwl_path/amazon-cloudwatch-agent.json $cwl_path/etc/amazon-cloudwatch-agent.d/default >> /var/log/userdata 2>&1
cp -f $cwl_path/amazon-cloudwatch-agent.json $cwl_path/etc/amazon-cloudwatch-agent.json >> /var/log/userdata 2>&1
systemctl restart amazon-cloudwatch-agent && systemctl status amazon-cloudwatch-agent >> /var/log/userdata 2>&1

#systemctl stop amazon-cloudwatch-agent #too expensive $$$

#aws ssm agent
echo "ssm setup" >> /var/log/userdata 2>&1
systemctl restart amazon-ssm-agent && systemctl enable amazon-ssm-agent >> /var/log/userdata 2>&1
rm -f /etc/amazon/ssm/seelog.xml
cat <<"EOF" >> /etc/amazon/ssm/seelog.xml
<seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500" minlevel="info">
    <exceptions>
        <exception filepattern="test*" minlevel="error"/>
    </exceptions>
    <outputs formatid="fmtinfo">
        <console formatid="fmtinfo"/>
        <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5"/>
        <filter levels="error,critical" formatid="fmterror">
            <rollingfile type="size" filename="/var/log/amazon/ssm/errors.log" maxsize="10000000" maxrolls="5"/>
        </filter>
		<custom name="cloudwatch_receiver" formatid="fmtdebug" data-log-group="${LOG_GROUP}"/>
    </outputs>
    <formats>
        <format id="fmterror" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
        <format id="fmtdebug" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
        <format id="fmtinfo" format="%Date %Time %LEVEL %Msg%n"/>
    </formats>
</seelog>
EOF
cat /etc/amazon/ssm/seelog.xml >> /var/log/userdata
systemctl restart amazon-ssm-agent && systemctl status amazon-ssm-agent >> /var/log/userdata

#steamcmd install
mkdir /opt/valheim && mkdir /opt/steam
cd /opt/steam
echo "steam download" >> /var/log/userdata 2>&1
until $(wget http://media.steampowered.com/installer/steamcmd_linux.tar.gz); do
echo 'waiting for dns' >> /var/log/userdata 2>&1
	sleep 3
done
echo "steam unpack" >> /var/log/userdata 2>&1
tar -xvzf steamcmd_linux.tar.gz >> /var/log/userdata 2>&1
echo "install game" >> /var/log/userdata 2>&1
/opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/valheim +app_update ${APP_ID} validate +exit >> /var/log/userdata 2>&1
ln -s /opt/steam/steamcmd.sh /sbin/steamcmd.sh

#valheim executor
echo "valheim config" >> /var/log/userdata 2>&1
rm -f /opt/valheim/start_valheim.sh
cat <<"EOF" > /opt/valheim/start_valheim.sh.template
#!/bin/bash
export templdpath=\$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:\$LD_LIBRARY_PATH
export SteamAppId=892970
#the app id above is incorrect, keep it that way

cd /opt/valheim
./valheim_server.x86_64 -name "${WORLD_NAME}" -port 2456 -world "${WORLD_DISPLAY}" -password "${WORLD_PASS}"

export LD_LIBRARY_PATH=$templdpath
EOF
cp /opt/valheim/start_valheim.sh.template /opt/valheim/start_valheim.sh
chmod 700 /opt/valheim/start_valheim.sh
echo "journalctl --unit=valheimserver --reverse" > /opt/steam/check_log.sh
chmod 700 /opt/steam/check_log.sh

#systemd config
echo "systemd config" >> /var/log/userdata 2>&1
rm -f /etc/systemd/system/valheimserver.service
cat <<"EOF" > /etc/systemd/system/valheimserver.service
[Unit]
Description=Valheim Server
Wants=network-online.target
After=syslog.target network.target nss-lookup.target network-online.target
[Service]
Type=simple
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3
User=root
Group=root
ExecStartPre=/opt/steam/steamcmd.sh +login anonymous +force_install_dir /opt/valheim/ +app_update ${APP_ID} validate +exit
ExecStart=/opt/valheim/start_valheim.sh
ExecReload=/bin/kill -s HUP \$MAINPID
KillSignal=SIGINT
WorkingDirectory=/opt/valheim
LimitNOFILE=100000
[Install]
WantedBy=multi-user.target
EOF

#scripts
echo "setting backup script" >> /var/log/userdata 2>&1
cat <<"EOF" > /opt/valheim/s3_backup.sh
#!/bin/bash
systemctl stop valheimserver
world_path=$(mount | grep Valheim | awk '{ print $3 }')
for i in $(ls $world_path/${WORLD_NAME}.*); do 
  aws s3 cp $i s3://${BUCKET_NAME}/$(date +"%Y_%m_%d_%I_%M_%p")/; 
done
systemctl start valheimserver
EOF
chmod 700 /opt/valheim/s3_backup.sh

echo "completed" >> /var/log/userdata 2>&1

systemctl daemon-reload

sleep 10

echo "mount efs" >> /var/log/userdata 2>&1
systemctl stop valheimserver
rm -rf ${GAME_DATA} && mkdir ${GAME_DATA} -p >> /var/log/userdata 2>&1
mount -t efs -o tls,accesspoint=${EFS_AP} ${EFS_ID}: ${GAME_DATA} >> /var/log/userdata 2>&1
  if [ -z $(cat /etc/fstab | grep Valheim) ]; then
      echo "${EFS_ID} ${GAME_DATA} efs _netdev,noresvport,tls,accesspoint=${EFS_AP} 0 0" >> /etc/fstab
  fi
mount | grep Valheim >> /var/log/userdata 2>&1

systemctl start valheimserver && systemctl enable valheimserver
systemctl status valheimserver >> /var/log/userdata 2>&1

#892970
#896660
#/root/.config/unity3d/IronGate/Valheim/worlds
