<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Tabla de Datos</title>
</head>
<body>
    <h1>Datos de DynamoDB</h1>
    <div id="hostname"></div>
    <table id="data-table">
        <thead>
            <tr>
                <th>Equipo</th>
                <th>Campeonatos</th>
            </tr>
        </thead>
        <tbody>
            <?php
            // Get the API Gateway URL from environment variable or configuration
            $api_url = getenv('API_GATEWAY_URL');
            
            // Fetch data from API Gateway
            $ch = curl_init();
            curl_setopt($ch, CURLOPT_URL, $api_url);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            
            $response = curl_exec($ch);
            $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);

            if ($http_code === 200) {
                $equipos = json_decode($response, true);
                if (is_array($equipos)) {
                    foreach ($equipos as $equipo) {
                        echo "<tr><td>{$equipo['equipo']}</td><td>{$equipo['campeonatos']}</td></tr>";
                    }
                } else {
                    echo "<tr><td colspan='2'>Error: Invalid data format</td></tr>";
                }
            } else {
                echo "<tr><td colspan='2'>Error fetching data from API</td></tr>";
            }
            ?>
        </tbody>
    </table>

    <script>
        window.onload = function() {
            fetch('/hostname.php')
                .then(response => response.text())
                .then(hostname => {
                    document.getElementById('hostname').innerText = "Servidor Hostname: " + hostname;
                })
                .catch(error => console.error('Error al obtener hostname:', error));
        };
    </script>
</body>
</html>
