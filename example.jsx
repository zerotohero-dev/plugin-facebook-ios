function testPlugin()
{
    ///////////////////////////////////////////////////////////////

    // Facebook instance
    var fb = new FBClass();

    ///////////////////////////////////////////////////////////////

    // Open Session
    fb.openSessionOnSuccessOnError(
        ["public_profile","user_friends"],
        function(e){
            // alert("Success");
            alert(e.data);
        },
        function(e){
            // alert("Error");
            alert(e.message);
        }
    );

    ///////////////////////////////////////////////////////////////

    // Close Session
    fb.closeSession();

    ///////////////////////////////////////////////////////////////

    // User Details
    fb.userDetailsOnSuccessOnError(
        function(e){
            alert("Success");
            alert(e.name);
        },
        function(e){
            alert("Error");
            alert(e.message);
        }
    );

    ///////////////////////////////////////////////////////////////

    // Post Status Update
    fb.postStatusUpdateOnSuccessOnError(
        "Smartface Plugin Test",
        function(e){
            alert("Success");
        },
        function(e){
            alert("Error");
        }
    );

    ///////////////////////////////////////////////////////////////

    // Show Friend Picker
    fb.showFriendPickerOnSelectedOnCancelledOnError(
        false,
        function(e){
            alert("OnSelected");
        },
        function(e){
            alert("OnCancelled");
        },
        function(e){
            alert("OnError");
        }
    );

    ///////////////////////////////////////////////////////////////

    // Get Friends List
    fb.getFriendsListOnSuccessOnError(
        function(e){
            alert("Success");
            alert(e[0].name);
        },
        function(e){
            alert("Error");
        }
    );

    ///////////////////////////////////////////////////////////////

    // RequestWithPath
    fb.requestWithPathParamsHttpMethodOnSuccessOnError(
        "/fql",
        "SELECT message FROM status  WHERE uid=me()",
        "GET",
        function(e){
            alert("Success");
            alert(JSON.stringify(e));
        },
        function(e){
            alert(e.message);
        }
    );

    ///////////////////////////////////////////////////////////////

    // IsSessionActive
    alert(fb.isSessionActive());

    ///////////////////////////////////////////////////////////////
}