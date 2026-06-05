<?php require_once 'auth.php'; require_once 'config.php';
$db = getDB();
$entrepots = $db->query("SELECT e.*,
    COUNT(DISTINCT s.produit_id) as nb_produits,
    COALESCE(SUM(s.quantite), 0) as total_stock
    FROM entrepots e
    LEFT JOIN stocks s ON s.entrepot_id = e.id
    GROUP BY e.id
    ORDER BY e.id")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>LOGISTIA — Entrepôts</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e0e0e0; }
        header { background: #1a1d27; padding: 20px 40px; display: flex; align-items: center; justify-content: space-between; border-bottom: 2px solid #2563eb; }
        header h1 { font-size: 1.8rem; color: #2563eb; letter-spacing: 2px; }
        header nav a { color: #e0e0e0; text-decoration: none; margin-left: 25px; font-size: 0.95rem; }
        header nav a:hover { color: #2563eb; }
        .logout { background: #ef444422; color: #ef4444 !important; padding: 5px 12px; border-radius: 6px; }
        .container { padding: 30px 40px; }
        .section { background: #1a1d27; border-radius: 10px; padding: 25px; margin-bottom: 25px; }
        .section h2 { font-size: 1.1rem; margin-bottom: 15px; color: #2563eb; border-bottom: 1px solid #2d3148; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; }
        th { text-align: left; padding: 10px; font-size: 0.85rem; color: #9ca3af; border-bottom: 1px solid #2d3148; }
        td { padding: 10px; font-size: 0.9rem; border-bottom: 1px solid #1f2235; }
        .progress { background: #2d3148; border-radius: 10px; height: 8px; margin-top: 4px; }
        .progress-bar { background: #2563eb; border-radius: 10px; height: 8px; }
    </style>
</head>
<body>
<header>
    <h1>⬡ LOGISTIA</h1>
    <nav>
        <a href="index.php">Dashboard</a>
        <a href="entrepots.php">Entrepôts</a>
        <a href="stocks.php">Stocks</a>
        <a href="commandes.php">Commandes</a>
        <a href="clients.php">Clients</a>
        <a href="logout.php" class="logout">⏻ <?= $_SESSION['nom'] ?></a>
    </nav>
</header>
<div class="container">
    <div class="section">
        <h2>🏭 Entrepôts</h2>
        <table>
            <tr><th>Nom</th><th>Ville</th><th>Adresse</th><th>Produits</th><th>Stock total</th><th>Capacité</th></tr>
            <?php foreach ($entrepots as $e):
                $pct = $e['capacite_max'] > 0 ? min(100, round($e['total_stock'] / $e['capacite_max'] * 100)) : 0;
            ?>
            <tr>
                <td><?= htmlspecialchars($e['nom']) ?></td>
                <td><?= htmlspecialchars($e['ville']) ?></td>
                <td><?= htmlspecialchars($e['adresse']) ?></td>
                <td><?= $e['nb_produits'] ?></td>
                <td><?= $e['total_stock'] ?></td>
                <td>
                    <?= $pct ?>% / <?= $e['capacite_max'] ?>
                    <div class="progress"><div class="progress-bar" style="width:<?= $pct ?>%"></div></div>
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</div>
</body>
</html>
