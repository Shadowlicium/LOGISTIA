<?php require_once 'auth.php'; require_once 'config.php';
$db = getDB();
$commandes = $db->query("SELECT c.id, cl.nom as client, cl.secteur, e.nom as entrepot,
    c.statut, c.date_commande, c.date_livraison,
    COUNT(lc.id) as nb_lignes,
    SUM(lc.quantite) as total_articles
    FROM commandes c
    JOIN clients cl ON cl.id = c.client_id
    JOIN entrepots e ON e.id = c.entrepot_id
    LEFT JOIN lignes_commande lc ON lc.commande_id = c.id
    GROUP BY c.id, cl.nom, cl.secteur, e.nom, c.statut, c.date_commande, c.date_livraison
    ORDER BY c.date_commande DESC")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>LOGISTIA — Commandes</title>
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
        .badge.en_attente { background: #fbbf2422; color: #fbbf24; }
        .badge.en_cours { background: #3b82f622; color: #3b82f6; }
        .badge.livree { background: #10b98122; color: #10b981; }
        .secteur { background: #2d3148; padding: 2px 8px; border-radius: 5px; font-size: 0.8rem; }
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
        <h2>📦 Commandes</h2>
        <table>
            <tr><th>#</th><th>Client</th><th>Secteur</th><th>Entrepôt</th><th>Articles</th><th>Statut</th><th>Date commande</th><th>Livraison prévue</th></tr>
            <?php foreach ($commandes as $c): ?>
            <tr>
                <td>#<?= $c['id'] ?></td>
                <td><?= htmlspecialchars($c['client']) ?></td>
                <td><span class="secteur"><?= htmlspecialchars($c['secteur']) ?></span></td>
                <td><?= htmlspecialchars($c['entrepot']) ?></td>
                <td><?= $c['total_articles'] ?> (<?= $c['nb_lignes'] ?> lignes)</td>
                <td><span class="badge <?= $c['statut'] ?>"><?= $c['statut'] ?></span></td>
                <td><?= date('d/m/Y H:i', strtotime($c['date_commande'])) ?></td>
                <td><?= $c['date_livraison'] ? date('d/m/Y', strtotime($c['date_livraison'])) : '—' ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</div>
</body>
</html>
