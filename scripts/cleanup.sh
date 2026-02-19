#!/bin/bash
echo "Nettoyage des images Docker..."
docker image prune -f
echo "Nettoyage terminé ✅"
```

---

### `.gitignore`
```
reports/
*.json
__pycache__/
*.pyc
.env
```

---

### `app/requirements.txt`
```
flask==3.0.0