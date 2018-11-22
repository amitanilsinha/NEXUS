Configuration Configure-Website
{
  param (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$MachineName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$WebSitePrefix,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$DevPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$UatPublicDNS,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]     
        [string]$ProdPublicDNS



  )

  Node $MachineName
  {  
            LocalConfigurationManager 
        {
            RebootNodeIfNeeded = $true
        }


         #Install the IIS Role
          WindowsFeature IIS
         {
          Ensure = “Present”
          Name = “Web-Server”
         }

         #Install ASP.NET 4.5
         WindowsFeature ASP
         {
          Ensure = “Present”
          Name = “Web-Asp-Net45”
         }

         WindowsFeature WebServerManagementConsole
         {
          Name = "Web-Mgmt-Console"
          Ensure = "Present"
         }
         File devfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\dev'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }
         File uatfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\uat'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }  
         File prodfolder
         {
            Type = 'Directory'
            DestinationPath = 'C:\inetpub\wwwroot\prod'
            Ensure = "Present"
            DependsOn       = '[WindowsFeature]ASP'
         }

          xWebsite DevWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix + '-dev'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\dev'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $DevPublicDNS
                                 }

                                )
            DependsOn       = '[File]devfolder'

         } 
         xWebsite UatWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-uat'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\uat'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $UatPublicDNS
                                 }

                                )
            DependsOn       = '[File]uatfolder'
         }

         xWebsite prodWebsite
         {
            Ensure          = 'Present'
            Name            = $WebSitePrefix +'-prod'
            State           = 'Started'
            PhysicalPath    = 'C:\inetpub\wwwroot\prod'
            BindingInfo     = @( MSFT_xWebBindingInformation
                                 {
                                   Protocol              = "HTTP"
                                   Port                  = 80
                                   HostName = $ProdPublicDNS
                                 }

                                )
            DependsOn       = '[File]prodfolder'
         }

  }
} 
