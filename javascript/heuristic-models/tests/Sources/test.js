function test(url) {
    const req = new XMLHttpRequest();
    req.open(url);
    req.send("foo");
    console.log(req.responseText);
}