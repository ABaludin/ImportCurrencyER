pageextension 50135 "AWR_Currencies" extends "Currencies"
{
    actions
    {
        addafter("Change Payment &Tolerance")
        {
            action("AWR_ImportCurrencyRates")
            {
                ApplicationArea = All;
                Image = UpdateXML;
                Promoted = true;
                PromotedCategory = Process;
                Caption = 'Downloading exchange rates from the ECB';
                RunObject = codeunit "AWR_Import currency ER";
            }
        }
    }
}