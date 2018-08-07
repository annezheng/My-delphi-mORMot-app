unit app_interface;

interface

type
  IAppServer = interface(IInvokable)
    ['{4E42E141-379C-4894-BAA7-AF208799056A}']
    function GetAllWords: Variant;
    function GetAllLinks: Variant;
    function GetAllPictures: Variant;
  end;

implementation

uses mORMot;

initialization
  TInterfaceFactory.RegisterInterfaces([TypeInfo(IAppServer)]);

end.


