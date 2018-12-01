Configuration DcsDemoWebsite {
  Node ("NodeIpOrName") {
    #Install IIS server role
    WindowsFeature IIS {
      Ensure = "Present"
      Name =  "Web-Server"
    }
    #Install ASP role
    WindowsFeature AspNet45 {
      Ensure = "Present"
      Name = "Web-Asp-Net45"
    }
  }
}