codeunit 50135 "AWR_Import currency ER"
{
    trigger OnRun();
    begin
        ImportCurrencyRates();
    end;

    local procedure ImportCurrencyRates();
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
        URL: Text;
    begin
        Url := 'http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml';
        if not Client.Get(Url, Response) then
            Error(Text001_Err, 'GET');
        Response.Content().ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(Text002_Err, Response.HttpStatusCode(), ResponseText);
        ParseXml(ResponseText);
    end;

    local procedure ParseXml(ResponseText: Text);
    var
        Currency: Record Currency;
        XmlDom: Codeunit "XML DOM Management";
        TypeHelper: Codeunit "Type Helper";
        XmlDoc: XmlDocument;
        XmlNodesList: XmlNodeList;
        Node: XmlNode;
        XmlDate: Date;
        RateVariant: Variant;
        Rate: Decimal;
    begin
        ResponseText := XmlDom.RemoveNamespaces(ResponseText);
        XmlDocument.ReadFrom(ResponseText, XmlDoc);
        XmlDoc.SelectSingleNode('Envelope/Cube/Cube', Node);
        Evaluate(XmlDate, GetAttributeValue(Node, 'time'), 9);
        XmlDoc.SelectNodes('Envelope/Cube/Cube/Cube', XmlNodesList);
        foreach Node in XmlNodesList do
            If Currency.Get(GetAttributeValue(Node, 'currency')) then begin
                RateVariant := Rate;
                TypeHelper.Evaluate(RateVariant, GetAttributeValue(Node, 'rate'), '', '');
                InsertCurrencyRate(XmlDate, Currency.Code, RateVariant);
            end;
    end;

    local procedure GetAttributeValue(Node: XmlNode; AttributeName: Text): Text
    var
        Attribute: XmlAttribute;
    begin
        If Node.AsXmlElement().Attributes().Get(AttributeName, Attribute) then
            exit(Attribute.Value());
    end;

    local procedure InsertCurrencyRate(RateDate: date; codCurrency: code[10]; Rate: Decimal);
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        IF Currency.GET(codCurrency) then begin
            CurrencyExchangeRate."Currency Code" := codCurrency;
            CurrencyExchangeRate."Starting Date" := RateDate;
            CurrencyExchangeRate."Exchange Rate Amount" := 1;
            CurrencyExchangeRate."Relational Exch. Rate Amount" := Rate;
            CurrencyExchangeRate."Adjustment Exch. Rate Amount" := 1;
            CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" := Rate;
            CurrencyExchangeRate."Fix Exchange Rate Amount" := CurrencyExchangeRate."Fix Exchange Rate Amount"::"Currency";
            IF NOT CurrencyExchangeRate.Insert() then
                CurrencyExchangeRate.Modify();
        end;
    end;

    var
        Text001_Err: Label 'The %1 call to the web service failed.';
        Text002_Err: Label 'The web service returned an error message:\ Status code: %1\ Description: %2';
}