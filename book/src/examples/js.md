# 🟨 JavaScript Пример

```html
<!DOCTYPE html>
<html>
<head>
  <title>RUVNAME JS Client</title>
</head>
<body>
  <button onclick="getStatus()">Получить статус</button>
  <pre id="output">...</pre>
  <script>
    function getStatus() {
      fetch("http://127.0.0.1:5311/status")
        .then(r => r.json())
        .then(data => {
          document.getElementById("output").textContent = JSON.stringify(data, null, 2);
        });
    }
  </script>
</body>
</html>
