import qrcode
import argparse

#get parameters needed for the connection string
def get_args():
    supported_encryption = ['WPA2', 'WPA','WPA3' ,'nopass']
    parser = argparse.ArgumentParser()
    parser.add_argument('--SSID', required=True, type=str, help='Name of the network you would like to connect to')
    parser.add_argument('--Encryption', required=False, default='wpa2', choices=supported_encryption, help='Encryption Type used by the SSID')
    parser.add_argument('--PASS', required=True, type=str, help='WiFi Password')
    return parser.parse_args()

#create wifi conmnection string
def createConnectionString(SSID:str,PWRD:str,Encryption:str):
    conString="WIFI:S:"+SSID+";T:"+Encryption+";P:"+PWRD+";;"
    return conString

#pop out a qr code
def generrateQRCode(inpt:str,name:str):
    img =qrcode.make(inpt)
    img.save(name+".png")


#run general actions her
#get args
gArgs=get_args()
#generateConnectionString
conStr=createConnectionString(gArgs.SSID,gArgs.PASS,gArgs.Encryption)
#pop out qr code
generrateQRCode(conStr,gArgs.SSID)
