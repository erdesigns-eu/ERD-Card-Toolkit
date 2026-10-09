unit UidProgrammingDemo.Main;

interface

uses ERD.Card.Demo.FamilyForm;

type
  /// <summary>Native family form alias using the shared form resource and worker lifecycle.</summary>
  TUidProgrammingDemoForm = TCardFamilyForm;

var
  /// <summary>Application-owned instance of the explicitly selected family demo.</summary>
  UidProgrammingDemoForm: TUidProgrammingDemoForm;

implementation

end.
