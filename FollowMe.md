# Follow Me with below 3 easy steps to have a quick demo for files securing in 2 mins.

## 1.Open a PowerShell window and run below cmd to install our module. 

```powershell
Install-Module -Name microsoft.security.toolkit -Scope CurrentUser
```
## 2.Get any of your OneDrive file path you interested to try from your local File Explorer or Online. So that we could use later. For example, we can get YourFilePath as below:

![image](https://github.com/user-attachments/assets/b275cba1-e78d-469a-83fc-1fd5769deed0)

Or Online: https://microsoftapc-my.sharepoint.com/my 

## 3. Save the below amisecure cmd to PowerShell ISE/Window but not running it yet. (Replace <YourFilePath> with your actual path.)

```powershell
amisecure -pathOfOneDrive <YourFilePath> -accessToken (Get-Clipboard)
```
To make the magic happen in MSFT tenant, for now you need to mannully copy your accesstoken to clipboard in Graph Explorer.  Go to https://developer.microsoft.com/en-us/graph/graph-explorer  and login your MSFT account. Copy your access token to clipboard.


![image](https://github.com/user-attachments/assets/548319be-f9f6-423d-a996-35071f53e04a)


Run the amisecure cmd you had previously to secure your files.

