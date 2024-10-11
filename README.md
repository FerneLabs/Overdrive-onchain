#### Terminal one (Make sure this is running)

```bash
# Run Katana
katana --disable-fee --allowed-origins "*"
```

#### Terminal two

```bash
# Build the example
sozo build

# Migrate the example
sozo migrate apply

```
sozo execute dojo_starter-playerActions create_account

sozo execute dojo_starter-playerActions get_account (vayan a la consola de katana y busquen el print)

sozo execute dojo_starter-playerActions add_win

sozo execute dojo_starter-playerActions get_account (ven los valores actualizados)
