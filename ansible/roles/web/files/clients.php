<?php require_once 'auth.php'; require_once 'config.php';
$db = getDB();
$clients = $db->query("SELECT cl.*,
    COUNT(DISTINCT c.id) as nb_commandes,
    SUM(CASE WHEN c.statut = 'en_attente' THEN 1 ELSE 0 END) as en_attente,
    SUM(CASE WHEN c.statut = 'en_cours' THEN 1 ELSE 0 END) as en_cours,
    SUM(CASE WHEN c.statut = 'livree' THEN 1 ELSE 0 END) as livrees
    FROM clients cl
    LEFT JOIN commandes c ON c.client_id = cl.id
    GROUP BY cl.id
    ORDER BY cl.nom")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>LOGISTIA — Clients</title>
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
        .badge { padding: 3px 10px; border-radius: 20px; font-size: 0.8rem; }
        .ecommerce { background: #8b5cf622; color: #8b5cf6; }
        .industriel { background: #f9731622; color: #f97316; }
        .mini { font-size: 0.8rem; color: #9ca3af; }
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
        <h2>👥 Clients</h2>
        <table>
            <tr><th>Nom</th><th>Secteur</th><th>Email</th><th>Téléphone</th><th>Commandes</th><th>Détail</th></tr>
            <?php foreach ($clients as $cl): ?>
            <tr>
                <td><?= htmlspecialchars($cl['nom']) ?></td>
                <td><span class="badge <?= $cl['secteur'] ?>"><?= $cl['secteur'] ?></span></td>
                <td><?= htmlspecialchars($cl['email']) ?></td>
                <td><?= htmlspecialchars($cl['telephone']) ?></td>
                <td><?= $cl['nb_commandes'] ?></td>
                <td class="mini">
                    ⏳ <?= $cl['en_attente'] ?> en attente &nbsp;
                    🔵 <?= $cl['en_cours'] ?> en cours &nbsp;
                    ✅ <?= $cl['livrees'] ?> livrées
                </td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</div>
</body>
</html>
