sap.ui.require(["sap/m/SearchField", "sap/ui/commons/TextField", "sap/m/InputBase", "sap/m/Input", "sap/base/util/UriParameters", "sap/m/FeedInput"],
    function (SearchField, TextField, InputBase, Input, UriParameters, FeedInput) {

        ////////
        // Sources of user-controlled data
        ////////
        // sap.ui.commons.SearchField.value
        var f = new SearchField();
        var remoteInput = f.value;
        var remoteInput = f.getValue();

        // sap.ui.commons.TextField.value
        var f = new TextField();
        var remoteInput = f.value;

        // sap.m.InputBase.value
        var ib = new InputBase();
        remoteInput = ib.value;

        // sap.m.Input.value
        // sap.m.Input#getValue()
        var input = new Input();
        remoteInput = input.value;
        remoteInput = input.getValue();

        // sap.m.FeedInput.value
        // sap.m.FeedInput#getValue()
        var fi = new FeedInput();
        remoteInput = fi.value;
        remoteInput = fi.getValue();

        // jQuery.sap.getUriParameters() return
        var value = jQuery.sap.getUriParameters().get("foo");

        // jQuery.sap.syncHead return
        var value = jQuery.sap.syncHead("url", "param")

        // jQuery.sap.syncGet return
        var value = jQuery.sap.syncGet("url", "param")

        // jQuery.sap.syncGetText return
        var value = jQuery.sap.syncGetText("url", "param")

        // jQuery.sap.syncPost return
        var value = jQuery.sap.syncPost("url", "param")

        // jQuery.sap.syncPostText return
        var value = jQuery.sap.syncPostText("url", "param")

        // UriParameters#get
        // UriParameters#getAll
        var uri = UriParameters.fromQuery(window.location.search)
        var sValue = uri.get("foo")
        var sValue = uri.getAll("foo")

        // sap.m.TextArea.value
        var f = new TextArea();
        var remoteInput = f.value;
        // sap.m.ComboBoxBase.value
        var f = new ComboBoxBase();
        var remoteInput = f.value;
    });
