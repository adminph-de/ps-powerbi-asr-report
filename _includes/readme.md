[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<p align="left">
  <a href="{{site.baseurl}}">
    <img src="{{site.baseurl}}/assets/images/logo.png" alt="Code Snipes" width="80%" height="80%">
  </a>
</p>

## Table of Contents

* [About the Project](#about-the-project)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Usage](#usage)
* [PowerBI](#powerbi)
* [References](#references)
* [Acknowledgements](#acknowledgements)


## About The Project
I am back on a project to migrate legacy virtual machines from a vSphere environment to Azure (Lift&Shift). It reminded me of my developed PowerBI report in my last migration project that draws an overview of the workload's replication status in Azure Site Recovery (ARS). This documentation you are reading is the new customized version of my PowerBI report PowerShell script. I will describe in detail how you use the PowerShell script to create a CSV file and attach the output to a PowerBI report. But before I start with the steps to use it, let me say, I am not a PowerBI expert. The example report you find in my repository is my limit to build reports. You might be more skilled in developing fancy reports, and you are welcome to share releases based on the data source output of my PowerShell script. As we all know, sharing is the foundation of being successful in our job. Joining people's knowledge and educate ourselves to deploy the best possible solution for our projects.

>Suppose you prefer a less detailed description with only the highlights of what you need to use. Follow my specifications (Readme) in my [Git Repository](https://github.com/adminph-de/ps-powerbi-asr-report/tree/master). It describes only the necessary steps to run, without great explanations.

You can find a list of all [Reference](#references) links at the end of this article.


## Prerequisites

Before we go ahead, you need to check some prerequisites to run the script and use the report. First of all, you need, of course, an Azure Account, a subscription, and it is more than help you know about Azure Site Recovery (ARS) and maybe also a migration project or a disaster recovery project already running in your Subscription. It helps if you already have some data to collect, so the report shows you real data you are familiar.

You need [PowerShell](https://docs.microsoft.com/en-us/powershell/) installed on your computer from where you like to execute the script or, if you want to do it on Microsoft Visual Studio Code, you can try the Remote-Connection and let the code run in an isolated Docker container. Find the instruction on how to run here [Using Azure PowerShell in Docker](https://docs.microsoft.com/en-us/powershell/azure/azureps-in-docker?view=azps-4.4.0). It can be helpful if you use a macOS or Linux. I also played around with [Ubuntu WSL](https://ubuntu.com/wsl) on Windows 10 an build my Azure image, based on a Ubuntu distribution. It contains all I need to manage our Azure environment by using AzureCLI, PowerShell Commands, and Scripts, as you can shed. There plenty of possibilities to interact with Azure. Use your preferred one. 

No matter what you choose to use, you need, in addition to PowerShell, the Azure AZ module installed. Here the simple installation (it works the same way in the Docker container and for WSL images)
[InstallAzure Module "AZ"](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.4.0)
```powershell
if ($PSVersionTable.PSEdition -eq 'Desktop' -and (Get-Module -Name AzureRM -ListAvailable)) {
    Write-Warning -Message ('Az module not installed. Having both the AzureRM and ' +
      'Az modules installed at the same time is not supported.')
} else {
    Install-Module -Name Az -AllowClobber -Scope CurrentUser
}
```
Getting a graphical output of the collected data, Microsoft's PowerBI is good to have as well. It is not free, but you can get a trial license to play around. Find the information on installing and get a free trial license at [Microsoft's PowerBI Homepage](https://powerbi.microsoft.com/en-us/). For all of you who already use PowerBI, I don't think you need explanations on that.

[Git](https://git-scm.com/downloads) for your operating system helps to work and interact with git repositories. It is available for Windows, Linux, and macOS. Finding the version that fits your OS at:
````html
https://git-scm.com/downloads
````
You can also download a [*.zip or *.tar release](https://github.com/adminph-de/ps-powerbi-asr-report/releases) instead of using [Git](https://git-scm.com/downloads) clone to get the source code.

Now it is time to start playing with the script and getting the first results out of Azure Site Recovery (ASR).

## Installation

There is nothing really to install, apart from the [Prerequisites](#prerequisites) above. It only requires the script on your computer to execute it, either with Git clone or download. That's it!

### Git clone:
```html
git clone --branch release-v1.0 https://git.com/adminph-de/ps-powerbi-asr-report.git
``` 
### Download a *.zip or *.tar file:
```
https://github.com/adminph-de/ps-powerbi-asr-report/releases/tag/release-v1.0
```
>Check if there is a new [release](https://github.com/adminph-de/ps-powerbi-asr-report/releases) and change the  **--branch** or the **download URL** if there is a new one.

That's it, nothing else to install.

## Usage

Open a PowerShell command interface and navigate to the folder where you cloned or downloaded the repository. You need to provide an SPN and grand access on your Azure Subscription. I explained in the following steps.

### Folder- and Files

Reposotory folder structure (with Explainations)
```
.
├── example
|   ├── report.csv
|   └── relprt.pbix
├── images
|   ├── logo.pgn
|   └── screenshot.pgn
├── .gitignore
├── LICENSE
├── README.md
├── report.json
├── report.ps1
```

The files you need are the following

| FOLDER      | FILE | Desctiption                                                        | 
|:--------------|:------------------------------------------------------------------------|
| example       | **report.csv**  | Excample CSV output with dummy data                   |
|:--------------|:------------------------------------------------------------------------|
| example       | **report.pbix** | PowerBI example report bulid with Microsoft's PowerBI |
|:--------------|:------------------------------------------------------------------------|
| .             | **report.json** | JSON file that contains the vatiables                 |
|:--------------|:------------------------------------------------------------------------|
| .             | **report.ps1**  | PowerShell Script to get the output CSV file          |
|:--------------|:------------------------------------------------------------------------|

Focus is on **report.json** and **report.ps1**. This is were you connect to Azure and get the CSV output.
I will explain how to use them and how to run.

### Create an Azure Service Principal (SPN) Login
Simplifying the run of the script and in regards to using it in an automated matter.  Find a detailed description of how you can create it at Microsoft's Homepage. Here the direct links: 

* [Azure Service Principal in the Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/ howto-create-service-principal-portal)
* [Azure service principal with Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-4.5.0)
* [Azure service principal with the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest)

>It is essential to write down (copy and paste) the SPN Password. You will not have access to it to show it again after creation. If you didn't write it down, don't worry, you can create a new password if necessary.

After the successful creation of the SPN, you need to grant access to the account. Either on Subscription Level or granular on the particular resource groups that contain your Backup- and Recovery Vaults, you like to get an output. Do it on the Portal, use AzureCLI or Powershell. It needs at least **read** access to the Subscription(s) or to the particular Resource Group(s) where you placed your Azure Backup- and Recovery vaults. Do this the same way as you grand permissions to a normal ADD user account.

### Modify the JSON file (report.json)

In the next step, you add the login information into the JSON file. I don't think I have to explain how sensible those files will be if you filed in the data. Store the JSON file on a place with limited access to prevent misuse of the information.

| VARIABLE      | DESCRIPTION                                                   | 
|:--------------|:--------------------------------------------------------------|
| **delimiter** | Delimiter of the output JSON file (Keep it if unsure)         |
|:--------------|:--------------------------------------------------------------|
| **location**  | Output File location of the report.cvs (Keep it if unsure)    |
|:--------------|:--------------------------------------------------------------|
| **TENANT_ID** | Your Azuer Tentant ID                                         |
|:--------------|:--------------------------------------------------------------|
| **SPN_ID**    | Your Azuer Service Princible ID                               |
|:--------------|:--------------------------------------------------------------|
| **SPN_PW**    | Password of the Service Princible ID                          |
|:--------------|:--------------------------------------------------------------|
| **name**      | Name of your Subscription. Divided by **,** (comma)           |
|:--------------|:--------------------------------------------------------------|

```json
{
  "delimiter": ";",
  "location":"reports",
  "login": {
      "TENANT_ID": "00000000-0000-0000-0000-00000000000",
      "SPN_ID": "00000000-0000-0000-0000-00000000000",
      "SPN_PW": "yourSpnSecret"
  },
  "subscription": [
      { "name":[ "prod", "test", "dev" ] }
  ]
}
```

### Execute the PowerShell Script (report.ps1)

After saving the JSON file, you are ready to run the script by injecting the settings you did in the JSON file into the PowerShell script, by executing the following command:

```bash
report.ps1 -JsonFile report.json
````

>If you get error messages, check the SPN and the access you grand to the account. You need at least **read** access, and sometimes we faced the issue that the report needs **contributor** access on the Subscription or the particular Resource Groups. I could not figure out why this is the case sometimes. Also, check your setting in the JSON file; maybe you misspelled the fancy ID numbers or the name of your Azure Subscription(s). Check your configuration in an error case and execute the script again.

After a successful run, you will get a **report.csv** file created with the output of the report gathering process. You can check the result by opening the file in a Text-Editor or with as an example Microsoft Excel to see the RAW data.


## PowerBI

As I said at the beginning of this article, I am not a PowerBI expert. My knowledge about the application is limited to simple reporting if I need more, we have a department who does the whole day nothing else than dealing with PowerBI reports and building them. 

Visualizing your result, navigate to the **example** folder and exchange the **report.csv** file with the created one you build. Open PowerBI and do a refresh on the data. It will show you the results, based on your **report.csv** file. A report can look like this example:

<p align="left">
  <a href="{{site.baseurl}}">
    <img src="{{site.baseurl}}/assets/images/screenshot.png" alt="Code Snipes" width="100%" height="100%">
  </a>
</p>

Feel free to modify the **report.pbix** file or create your own.


## Acknowledgements

* [Janaina Laguardia Areal Hyldvang, Ph.D.](https://www.linkedin.com/in/janainahyldvang/)
* [Jakob Daugaard](https://www.linkedin.com/in/jakobdaugaard/?locale=en_US)
* [Senthil Kumar Bose](https://www.linkedin.com/in/senthil-kumar-bose-6900582/)
* [Javed Khan](https://www.linkedin.com/in/javed-khan-674863164/)

## References

* [My Git Repository of all what you need](https://github.com/adminph-de/ps-powerbi-asr-report/tree/master)
* [InstallAzure Module "AZ"](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.4.0)
* [Using Azure PowerShell in Docker](https://docs.microsoft.com/en-us/powershell/azure/azureps-in-docker?view=azps-4.4.0)
* [Ubuntu on WSL](https://ubuntu.com/wsl)
* [Windows Subsystem for Linux](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
* [Microsoft's PowerBI Homepage](https://powerbi.microsoft.com/en-us/)
* [Git for your OS](https://git-scm.com/downloads)
* [Azure Service Principal in the Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/ howto-create-service-principal-portal)
* [Azure service principal with Azure PowerShell](https://docs.microsoft.com/en-us/powershell/azure/create-azure-service-principal-azureps?view=azps-4.5.0)
* [Azure service principal with the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli?view=azure-cli-latest)


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/adminph-de/ps-azure-bginfo.svg?style=flat-square
[contributors-url]: https://github.com/adminph-de/ps-azure-bginfo/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/adminph-de/ps-azure-bginfo.svg?style=flat-square
[forks-url]: https://github.com/adminph-de/ps-azure-bginfo/network/members
[stars-shield]: https://img.shields.io/github/stars/adminph-de/ps-azure-bginfo.svg?style=flat-square
[stars-url]: https://github.com/adminph-de/ps-azure-bginfo/stargazers
[issues-shield]: https://img.shields.io/github/issues/adminph-de/ps-azure-bginfo.svg?style=flat-square
[issues-url]: https://github.com/adminph-de/ps-azure-bginfo/issues
[license-shield]: https://img.shields.io/github/license/adminph-de/ps-azure-bginfo.svg?style=flat-square
[license-url]: https://github.com/adminph-de/ps-azure-bginfo/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=flat-square&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/patrickhayo/?locale=en_US
[product-screenshot-1]: {{site.baseurl}}/assets/images/screenshot1.png