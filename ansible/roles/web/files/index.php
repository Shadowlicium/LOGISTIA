<?php require_once 'auth.php'; require_once 'config.php';
$db = getDB();

$nb_entrepots = $db->query("SELECT COUNT(*) FROM entrepots")->fetchColumn();
$nb_clients = $db->query("SELECT COUNT(*) FROM clients")->fetchColumn();
$nb_produits = $db->query("SELECT COUNT(*) FROM produits")->fetchColumn();
$nb_commandes = $db->query("SELECT COUNT(*) FROM commandes")->fetchColumn();
$alertes = $db->query("SELECT p.nom, s.quantite, s.seuil_alerte, e.nom as entrepot
    FROM stocks s
    JOIN produits p ON p.id = s.produit_id
    JOIN entrepots e ON e.id = s.entrepot_id
    WHERE s.quantite <= s.seuil_alerte")->fetchAll(PDO::FETCH_ASSOC);
$commandes_recentes = $db->query("SELECT c.id, cl.nom as client, e.nom as entrepot, c.statut, c.date_commande
    FROM commandes c
    JOIN clients cl ON cl.id = c.client_id
    JOIN entrepots e ON e.id = c.entrepot_id
    ORDER BY c.date_commande DESC LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
?>
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>LOGISTIA — Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', sans-serif; background: #0f1117; color: #e0e0e0; }
        header { background: #1a1d27; padding: 20px 40px; display: flex; align-items: center; justify-content: space-between; border-bottom: 2px solid #2563eb; }
        header h1 { font-size: 1.8rem; color: #2563eb; letter-spacing: 2px; }
        header nav a { color: #e0e0e0; text-decoration: none; margin-left: 25px; font-size: 0.95rem; }
        header nav a:hover { color: #2563eb; }
        .logout { background: #ef444422; color: #ef4444 !important; padding: 5px 12px; border-radius: 6px; }
        .container { padding: 30px 40px; }
        .cards { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-bottom: 30px; }
        .card { background: #1a1d27; border-radius: 10px; padding: 25px; text-align: center; border-top: 3px solid #2563eb; }
        .card .number { font-size: 2.5rem; font-weight: bold; color: #2563eb; }
        .card .label { font-size: 0.9rem; color: #9ca3af; margin-top: 5px; }
        .section { background: #1a1d27; border-radius: 10px; padding: 25px; margin-bottom: 25px; }
        .section h2 { font-size: 1.1rem; margin-bottom: 15px; color: #2563eb; border-bottom: 1px solid #2d3148; padding-bottom: 10px; }
        table { width: 100%; border-collapse: collapse; }
        th { text-align: left; padding: 10px; font-size: 0.85rem; color: #9ca3af; border-bottom: 1px solid #2d3148; }
        td { padding: 10px; font-size: 0.9rem; border-bottom: 1px solid #1f2235; }
        .badge { padding: 3px 10px; border-radius: 20px; font-size: 0.8rem; }
        .badge.en_attente { background: #fbbf2422; color: #fbbf24; }
        .badge.en_cours { background: #3b82f622; color: #3b82f6; }
        .badge.livree { background: #10b98122; color: #10b981; }
        .alerte { color: #ef4444; font-weight: bold; }
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
    <div class="cards">
        <div class="card"><div class="number"><?= $nb_entrepots ?></div><div class="label">Entrepôts</div></div>
        <div class="card"><div class="number"><?= $nb_clients ?></div><div class="label">Clients</div></div>
        <div class="card"><div class="number"><?= $nb_produits ?></div><div class="label">Produits</div></div>
        <div class="card"><div class="number"><?= $nb_commandes ?></div><div class="label">Commandes</div></div>
    </div>

    <?php if (!empty($alertes)): ?>
    <div class="section">
        <h2>⚠ Alertes stock</h2>
        <table>
            <tr><th>Produit</th><th>Entrepôt</th><th>Quantité</th><th>Seuil</th></tr>
            <?php foreach ($alertes as $a): ?>
            <tr>
                <td><?= htmlspecialchars($a['nom']) ?></td>
                <td><?= htmlspecialchars($a['entrepot']) ?></td>
                <td class="alerte"><?= $a['quantite'] ?></td>
                <td><?= $a['seuil_alerte'] ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
    <?php endif; ?>

    <div class="section">
        <h2>📦 Commandes récentes</h2>
        <table>
            <tr><th>#</th><th>Client</th><th>Entrepôt</th><th>Statut</th><th>Date</th></tr>
            <?php foreach ($commandes_recentes as $c): ?>
            <tr>
                <td>#<?= $c['id'] ?></td>
                <td><?= htmlspecialchars($c['client']) ?></td>
                <td><?= htmlspecialchars($c['entrepot']) ?></td>
                <td><span class="badge <?= $c['statut'] ?>"><?= $c['statut'] ?></span></td>
                <td><?= date('d/m/Y H:i', strtotime($c['date_commande'])) ?></td>
            </tr>
            <?php endforeach; ?>
        </table>
    </div>
</div>
</body>
</html>
