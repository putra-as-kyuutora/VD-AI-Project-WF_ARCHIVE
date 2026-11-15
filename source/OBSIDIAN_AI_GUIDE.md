# OBSIDIAN UI — Panduan Codebase untuk AI

> Dokumen ini ditulis agar AI (atau manusia) bisa **menganalisis dan memodifikasi** Obsidian UI tanpa membaca 5.000+ baris `Library.lua` dari awal.
> Semua nomor baris merujuk ke file **asli di repo** (versi commit `d244e90`). Jika file berubah, nomor baris bisa bergeser. Cari nama fungsinya dengan `grep`.
> Simpan file ini di root repo (mis. sebagai `AGENTS.md` / `CLAUDE.md`) supaya otomatis terbaca agen coding.

---

## 0. TL;DR

- **Apa ini:** library UI untuk **Roblox** (bahasa **Luau**), biasanya dipakai lewat executor script. Membuat window, tab, groupbox, toggle, slider, dropdown, color picker, keybind picker, notifikasi, tooltip, dll.
- **Gaya:** satu file besar (`Library.lua`) yang mengembalikan satu tabel `Library`. Tidak ada `require` / modul lain. Addon (`SaveManager`, `ThemeManager`) dimuat terpisah dan menerima `Library` lewat `:SetLibrary(Library)`.
- **Tidak ada build system, test, atau package manager.** Edit file `.lua` langsung. Verifikasi hanya bisa dilakukan di Roblox (Studio atau executor).
- **Line ending:** semua file memakai **CRLF** (`\r\n`). Pertahankan saat mengedit supaya diff tidak berantakan.
- **Dependensi eksternal saat runtime:** `game:HttpGet` untuk ikon Lucide (`Library.lua` baris ~455) dan untuk memuat library/addon di `Example.lua`. Jika gagal, ikon bernilai `nil` (aman, tidak crash).

---

## 1. Struktur Repo

| Path | Ukuran | Fungsi |
|---|---|---|
| `Library.lua` | 5.278 baris | **Seluruh library inti.** Lihat §3. |
| `addons/SaveManager.lua` | 495 baris | Simpan/muat konfigurasi (JSON) ke file executor. Lihat §9. |
| `addons/ThemeManager.lua` | 369 baris | Tema bawaan, tema kustom, UI pemilih tema. Lihat §10. |
| `Example.lua` | 724 baris | Contoh pemakaian lengkap semua elemen. **Sumber kebenaran terbaik untuk pola penggunaan.** |
| `README.md` | 961 baris | Dokumentasi API untuk pengguna (bisa tidak sinkron dengan kode). |
| `CHANGELOG.md` | 8 baris | Hanya satu entri (18.01.2024). Tidak dirawat. |
| `Example.png`, `LICENSE` | — | Gambar & lisensi. |

**Kalau README dan kode berbeda, percayai kode.**

---

## 2. Arsitektur & Konsep Inti

### 2.1 Hierarki objek (apa memanggil apa)

```
Library (tabel global, juga di getgenv().Library)
└─ Library:CreateWindow(WindowInfo)            -> Window
   ├─ Window:AddTab(Name, LucideIconName)      -> Tab        (metatable = BaseGroupbox)
   │   ├─ Tab:AddLeftGroupbox(Name) / AddRightGroupbox(Name) / AddGroupbox({Side,Name}) -> Groupbox
   │   ├─ Tab:AddLeftTabbox(Name?)  / AddRightTabbox(Name?)  / AddTabbox({Side,Name?})  -> Tabbox
   │   │    └─ Tabbox:AddTab(Name)             -> sub-tab    (metatable = BaseGroupbox)
   │   ├─ Tab:UpdateWarningBox({Visible,Title,Text,IsNormal})
   └─ Window:AddKeyTab(Name)                   -> KeyTab     (punya AddKeyBox; IsKeyTab = true)

Groupbox / sub-tab Tabbox / KeyTab  --(Funcs dari BaseGroupbox)-->
   AddLabel, AddButton, AddToggle, AddCheckbox, AddInput, AddSlider, AddDropdown, AddDivider
      (AddLabel & AddToggle/AddCheckbox ber-metatable BaseAddons ->) AddKeyPicker, AddColorPicker
```

### 2.2 Tiga "Funcs table" (penting untuk menambah fitur)

Di `Library.lua` ada dua blok `do ... end` besar, masing-masing mendefinisikan `local Funcs = {}`:

| Blok | Baris | `Funcs` berisi | Dipasang ke |
|---|---|---|---|
| **BaseAddons** | 1235–2007 | `AddKeyPicker`, `AddColorPicker` | `BaseAddons.__index = Funcs` (baris 2001). Dipasang via `setmetatable(Obj, BaseAddons)` pada **Label** (non-wrap), **Toggle**, **Checkbox**. |
| **BaseGroupbox** | 2008–3716 | `AddDivider`, `AddLabel`, `AddButton`, `AddCheckbox`, `AddToggle`, `AddInput`, `AddSlider`, `AddDropdown` | `BaseGroupbox.__index = Funcs` (baris 3712). Dipasang via `setmetatable(Tab/Groupbox/subTab, BaseGroupbox)`. |

Keduanya juga punya `__namecall` yang meneruskan ke `Funcs[Key](...)`.

**Konsekuensi praktis:**
- Menambah elemen baru yang bisa dipanggil dari groupbox → tambahkan `function Funcs:AddXxx(Idx, Info)` di dalam blok **BaseGroupbox** (sebelum baris 3712).
- Menambah addon yang menempel pada Label/Toggle → tambahkan di blok **BaseAddons** (sebelum baris 2001).
- `AddKeyPicker` / `AddColorPicker` **mengembalikan `self`** (objek induk), sehingga bisa dirantai: `Groupbox:AddToggle(...):AddColorPicker(...):AddKeyPicker(...)`.
- `AddLabel` dengan `DoesWrap = true` **tidak** diberi `BaseAddons` (baris ~2130), jadi tidak bisa memasang picker.

### 2.3 Pola pembuatan objek elemen (semua elemen mengikuti pola ini)

```lua
function Funcs:AddXxx(Idx, Info)
    Info = Library:Validate(Info, Templates.Xxx)   -- isi default dari tabel Templates (baris 107–253)
    local Groupbox = self                          -- self = Groupbox/Tab pemanggil
    local Container = Groupbox.Container

    local Xxx = { Text=..., Value=..., Callback=..., Changed=..., Disabled=..., Visible=..., Type="Xxx" }

    -- 1) Bangun Instance Roblox dengan New("Class", {props})
    -- 2) Definisikan method: Xxx:Display(), :UpdateColors(), :OnChanged(), :SetValue(), :SetDisabled(), :SetVisible(), :SetText()
    -- 3) Hubungkan event input (MouseButton1Click, dst)
    -- 4) Tooltip opsional: Library:AddTooltip(Info.Tooltip, Info.DisabledTooltip, HoverInstance)
    -- 5) Finalisasi:
    Xxx:Display()
    Groupbox:Resize()
    Xxx.Holder = Holder                      -- Instance root elemen (dipakai Search & visibilitas)
    table.insert(Groupbox.Elements, Xxx)     -- WAJIB agar ikut Search & Resize
    Options[Idx] = Xxx   -- atau Toggles[Idx]; Label/Button pakai Labels/Buttons
    return Xxx
end
```

Field `Type` (string) dipakai oleh `SaveManager.Parser`, `SetDPIScale`, `Library:Toggle`, `OnPlayerChange`, dan Search. **Selalu set `Type`.**

### 2.4 Catatan: `Tab` dan `Groupbox` berbagi `Funcs`
`Window:AddTab` melakukan `setmetatable(Tab, BaseGroupbox)` dengan `Tab.Container`. Namun `Tab:Resize()` milik Tab berbeda arti dari `Groupbox:Resize()`, dan Tab tidak punya `Elements`. Tab biasa hanya punya `Groupboxes`, `Tabboxes`, `Sides`. Sebaliknya **KeyTab** dibuat dengan `Elements = {}` dan `IsKeyTab = true`, jadi elemen (mis. `AddLabel`, `AddKeyBox`) memang bisa dipanggil langsung di KeyTab, seperti di `Example.lua`. Untuk tab biasa, selalu buat Groupbox/Tabbox dulu.

### 2.5 Registry global (state yang dibagikan)

| Tabel | Isi | Diisi oleh |
|---|---|---|
| `Library.Toggles[Idx]` | objek Toggle/Checkbox | `AddToggle`, `AddCheckbox` |
| `Library.Options[Idx]` | Input, Slider, Dropdown, KeyPicker, ColorPicker | masing-masing `AddXxx` |
| `Library.Labels[Idx]` | Label (kalau `Idx` diberikan; kalau tidak → `table.insert`) | `AddLabel` |
| `Library.Buttons[Idx]` | Button/SubButton (sama seperti Label) | `AddButton` |
| `Library.Tabs[Name]` | Tab | `AddTab`, `AddKeyTab` |
| `Library.Registry[Instance]` | `{Property = "SchemeKey" \| function}` untuk **theming** | `FillInstance`, `AddToRegistry` |
| `Library.DPIRegistry[Instance]` | `{Property = nilai-asli}` untuk **DPI scaling** | `FillInstance`, `UpdateDPI` |
| `Library.Signals` | koneksi event yang di-disconnect saat `Unload` | `GiveSignal` |
| `Library.UnloadSignals` | callback user saat `Unload` | `OnUnload` |

> **Bahaya:** `Idx` yang sama menimpa elemen lama **tanpa peringatan** (`Options[Idx] = ...`). Pastikan `Idx` unik, termasuk lintas Tabbox.

### 2.6 Sistem tema (`Library.Scheme` + `Registry`)

`Library.Scheme` (baris 75–85) menyimpan warna/font:

`BackgroundColor`, `MainColor`, `AccentColor`, `OutlineColor`, `FontColor`, `Font` (Font object), `Red`, `Dark`, `White`.

Mekanisme (`FillInstance`, baris 487–526):
1. Di `New("Frame", { BackgroundColor3 = "MainColor" })`, nilai **string** yang cocok dengan key `Library.Scheme` → disimpan di `Registry[Instance].BackgroundColor3 = "MainColor"` dan langsung diset dari Scheme.
2. Nilai **function** (mis. `function() return Library:GetBetterColor(...) end`) juga masuk Registry dan dievaluasi ulang tiap update tema.
3. `Library:UpdateColorsUsingRegistry()` (baris 381) menerapkan ulang semuanya. Dipanggil oleh `ThemeManager:ThemeUpdate()` dan `Library:SetFont()`.
4. Template per-class (`Templates.TextLabel`, dst.) otomatis memberi `FontFace="Font"` dan `TextColor3="FontColor"`.

**Aturan emas:** untuk warna yang harus ikut tema, **jangan** menulis `Instance.BackgroundColor3 = Color3...` langsung. Pakai string key Scheme di `New(...)`, atau tulis juga ke `Library.Registry[Instance].Prop`. Contoh pola yang benar dipakai di `Toggle:Display()` (baris 2730–2769) yang mengubah nilai *dan* `Library.Registry[Switch].BackgroundColor3`.

> Perilaku halus: jika `FillInstance` menerima properti yang sebelumnya ada di Registry, entri Registry itu **dihapus** (baris ~498, `ThemeProperties[k] = nil`) lalu nilai baru diset sebagai nilai biasa. Jadi memanggil `New` ulang dengan warna literal akan memutus theming.

### 2.7 DPI scaling

- `Library.DPIScale` (1 = 100%). `Library:SetDPIScale(percent)` (baris 403): contoh `75`, `100`, `125`.
- `FillInstance` otomatis menyimpan nilai asli `Position`, `Size`, `*Padding*`, dan `TextSize` ke `DPIRegistry`, lalu mengalikan dengan `DPIScale` lewat `ApplyDPIScale` / `ApplyTextScale`.
- Opsi pada tabel properti `New`:
  - `DPIExclude = { Position = true }` → properti itu **tidak** di-scale.
  - `DPIOffset = { Size = {8, 4} }` → tambahan offset (x, y) yang ikut di-scale.
- Jika Anda mengubah `Size/Position` instance secara manual setelah dibuat, panggil `Library:UpdateDPI(Instance, { Size = newValue })` agar nilai asli di DPIRegistry diperbarui (atau `{ Size = false }` untuk berhenti men-scale properti itu). Pola ini terlihat di `Tab:Resize` dan `UpdateWarningBox`.
- Ukuran yang dihitung dari `AbsoluteContentSize` (mis. `Groupbox:Resize`) dikalikan `Library.DPIScale` secara manual.

---

## 3. Peta `Library.lua` per Region

| Baris | Region | Isi |
|---|---|---|
| 1–20 | Service & shim executor | `cloneref`, `getgenv`, `protectgui`, `gethui`, `setclipboard` (semua dengan fallback). |
| 22–33 | Registry kosong | `Labels, Buttons, Toggles, Options`. |
| 35–90 | **Tabel `Library`** | Semua state & flag (lihat §4). |
| 92–106 | Deteksi platform | Menentukan `IsMobile` & `MinSize`. |
| 107–253 | **`Templates`** | Default properti Instance **dan** default `Info` tiap elemen (`Window`, `Toggle`, `Input`, `Slider`, `Dropdown`, `KeyPicker`, `ColorPicker`). **Ubah default di sini.** |
| 247–254 | `Places`, `Sizes` | Konstanta kecil. |
| 256–351 | Helper lokal | `ApplyDPIScale`, `ApplyTextScale`, `WaitForEvent`, `IsClickInput`, `IsHoverInput`, `GetTableSize`, `StopTween`, `Trim`, `GetPlayers`, `GetTeams`. |
| 353–484 | Registry/DPI/ikon/validasi | `UpdateKeybindFrame`, `AddToRegistry`, `RemoveFromRegistry`, `UpdateColorsUsingRegistry`, `UpdateDPI`, `SetDPIScale`, `GiveSignal`, `GetIcon`, `Validate`. |
| 486–543 | **Pembuat Instance** | `FillInstance`, `New`. |
| 545–631 | Instance utama | `ParentUI`, `ScreenGui`, `ModalElement`, `Cursor`, `NotificationArea`/`NotificationList`. |
| 633–953 | Helper UI | `GetBetterColor`, `GetDarkerColor`, `GetKeyString`, `GetTextBounds`, `MouseIsOverFrame`, `SafeCallback`, `MakeDraggable`, `MakeResizable`, `MakeCover`, `MakeLine`, `MakeOutline`, `AddDraggableButton`, `AddDraggableMenu`. |
| 955–1112 | **Context Menu** | `Library:AddContextMenu` (dipakai Dropdown, KeyPicker, ColorPicker). |
| 1114–1208 | **Tooltip** | `Library:AddTooltip`. |
| 1210–1233 | Lifecycle | `OnUnload`, `Unload`; ikon `CheckIcon`, `ArrowIcon`, `ResizeIcon`, `KeyIcon`. |
| 1235–2007 | **Blok BaseAddons** | `AddKeyPicker` (1238), `AddColorPicker` (1607). |
| 2008–3716 | **Blok BaseGroupbox** | `AddDivider` 2011, `AddLabel` 2031, `AddButton` 2144, `AddCheckbox` 2441, `AddToggle` 2637, `AddInput` 2856, `AddSlider` 3015, `AddDropdown` 3269. |
| 3718–3739 | Setelan global | `SetFont`, `SetNotifySide`. |
| 3741–3948 | **Notifikasi** | `Library:Notify`. |
| 3950–5250 | **`CreateWindow`** | Membangun frame utama (≈3950–4234), `Window:AddTab` (4238), `Window:AddKeyTab` (4801), `Library:Toggle` (5009), tombol mobile, **Search** (≈5100–5235), keybind toggle window. |
| 5252–5278 | Penutup | Handler Player/Team untuk Dropdown khusus, `getgenv().Library = Library`, `return Library`. |

---

## 4. State & Flag pada `Library`

| Field | Default | Arti |
|---|---|---|
| `IsMobile`, `DevicePlatform` | auto | Deteksi Android/iOS (Studio: TouchEnabled tanpa Mouse). |
| `ScreenGui` | — | Root GUI bernama `"Obsidian"`, `DisplayOrder = 999`. |
| `ActiveTab`, `Tabs` | nil / `{}` | Tab aktif dan semua tab (key = nama). |
| `KeybindFrame`, `KeybindContainer`, `KeybindToggles` | — | Panel daftar keybind (draggable). |
| `Notifications` | `{}` | Notifikasi aktif. |
| `ToggleKeybind` | `RightControl` | Tombol show/hide window. Boleh berupa **objek KeyPicker** (dicek di baris 5241). |
| `TweenInfo`, `NotifyTweenInfo` | 0.1s / 0.25s Quad Out | Dipakai semua animasi. |
| `Toggled`, `Unloaded` | false | Visibilitas window; flag sesudah `Unload`. |
| `NotifySide` | `"Right"` | `"Left"` / `"Right"`. |
| `ShowCustomCursor` | true | Kursor silang kustom saat menu terbuka. |
| `ForceCheckbox` | false | Jika true, `AddToggle` dialihkan ke `AddCheckbox`. |
| `ShowToggleFrameInKeybinds` | true | Tampilkan kotak status pada mode Toggle di panel keybind. |
| `NotifyOnError` | false | `SafeCallback` juga memunculkan notifikasi saat callback error. |
| `CantDragForced` | false | Dikunci oleh tombol "Lock" di mobile. |
| `MinSize` | 480×360 (mobile 480×240) | Ukuran minimum window. |
| `DPIScale` | 1 | Lihat §2.7. |
| `CornerRadius` | 4 | Diset ulang oleh `CreateWindow`. |
| `IsLightTheme` | false | Membalik arah `GetBetterColor` (terang ↔ gelap). |
| `Scheme` | lihat §2.6 | Palet warna & font. |
| `Registry`, `DPIRegistry` | `{}` | Lihat §2.5. |

---

## 5. Referensi API Library (fungsi publik)

### Siklus hidup & global
| Fungsi | Keterangan |
|---|---|
| `Library:CreateWindow(WindowInfo)` | Buat window. Field: `Title`, `Footer`, `Icon` (assetid/URL), `IconSize`, `Position`, `Size`, `Center`, `AutoShow`, `Resizable`, `CornerRadius`, `NotifySide`, `ShowCustomCursor`, `Font` (Enum.Font), `ToggleKeybind`, `MobileButtonsSide`. Ukuran dijepit ke viewport − 64 px. |
| `Library:Toggle(bool?)` | Tampilkan/sembunyikan window. Saat ditutup, semua popup (dropdown/colorpicker/keypicker) ikut ditutup. |
| `Library:Unload()` | Disconnect semua `Signals`, jalankan `UnloadSignals`, `ScreenGui:Destroy()`, `getgenv().Library = nil`. |
| `Library:OnUnload(fn)` | Daftarkan callback pembersihan. |
| `Library:GiveSignal(conn)` | Daftarkan koneksi agar otomatis lepas saat `Unload`. **Gunakan untuk setiap koneksi global baru** (UserInputService, RunService, dsb.). |
| `Library:Notify(infoOrString, time?, soundId?)` | Notifikasi. Bentuk tabel: `{Title, Description, Time, SoundId, Steps}`. `Time` bisa angka (detik) atau Instance (menunggu event). Mengembalikan `Data` dengan `:ChangeTitle`, `:ChangeDescription`, `:ChangeStep`, `:Resize`. |
| `Library:SetNotifySide(side)` | `"Left"`/`"Right"`. |
| `Library:SetFont(FontFaceOrEnum)` | Ganti font + refresh registry. |
| `Library:SetDPIScale(percent)` | Ganti skala (mis. 75/100/125). **Lihat catatan bug di §12.** |
| `Library:GetIcon(name)` | Ikon Lucide → `{Url, ImageRectOffset, ImageRectSize}` atau `nil`. |

### Helper yang sering dipakai saat memodifikasi
| Fungsi | Keterangan |
|---|---|
| `Library:Validate(table, template)` | Merge default **secara rekursif**. Mengubah (mutate) tabel yang dilewatkan. |
| `Library:SafeCallback(fn, ...)` | `pcall` + lempar ulang error via `task.defer`. **Semua callback user wajib lewat ini.** |
| `Library:AddToRegistry(inst, props)` / `RemoveFromRegistry` / `UpdateColorsUsingRegistry` | Kelola theming manual. |
| `Library:UpdateDPI(inst, props)` | Sinkronkan DPIRegistry (lihat §2.7). |
| `Library:GetBetterColor(c, add)` / `GetDarkerColor(c)` | Turunan warna untuk hover/border. |
| `Library:GetTextBounds(text, font, size, width?)` | Ukuran teks (RichText aktif). |
| `Library:MouseIsOverFrame(frame, mousePos)` | Hit-test manual (dipakai menutup popup). |
| `Library:MakeDraggable / MakeResizable / MakeCover / MakeLine / MakeOutline` | Pembangun komponen visual. |
| `Library:AddDraggableButton(text, fn)` / `AddDraggableMenu(name)` | Tombol/panel yang bisa digeser (mobile & keybind list). |
| `Library:AddContextMenu(holder, size, offset, list, activeCb)` | Popup generik; mengembalikan `{Open, Close, Toggle, SetSize, Menu, Active}`. |
| `Library:AddTooltip(info, disabledInfo, hoverInstance)` | Mengembalikan `{Disabled, Destroy, ...}`. |
| `Library:UpdateKeybindFrame()` | Hitung ulang lebar panel keybind. |

---

## 6. Referensi Elemen

Semua `Info` melewati `Validate(Info, Templates.X)`. Callback dipanggil lewat `SafeCallback`. **`Callback` dan `Changed` keduanya dipanggil** saat nilai berubah lewat `SetValue` (kecuali disebut lain).

### 6.1 Window / Tab / Groupbox / Tabbox
| API | Keterangan |
|---|---|
| `Window:AddTab(Name, Icon?)` | Tab biasa (2 kolom kiri/kanan). `Icon` = nama Lucide (`"user"`, `"settings"`). |
| `Window:AddKeyTab(Name)` | Tab sistem key; punya `Tab:AddKeyBox(expectedKey?, callback(success, text))` (baris 4877). |
| `Tab:AddLeftGroupbox(name)` / `AddRightGroupbox(name)` | Mengembalikan Groupbox. Disimpan di `Tab.Groupboxes[name]`. |
| `Tab:AddLeftTabbox(name?)` / `AddRightTabbox(name?)` | Kotak ber-tab. `Tabbox:AddTab(name)` → sub-tab yang bisa `AddToggle`, dst. |
| `Tab:UpdateWarningBox({Visible, Title, Text, IsNormal})` | Kotak peringatan di atas tab. `IsNormal=true` → warna netral, selain itu merah. |
| `Groupbox:Resize()` | Hitung ulang tinggi dari `AbsoluteContentSize`. Dipanggil setiap elemen berubah visibilitas. |
| `Groupbox.Elements` | Array semua elemen (dipakai Search). |

### 6.2 Label — `Groupbox:AddLabel(...)` (baris 2031)
Tiga bentuk panggilan:
```lua
AddLabel("teks")                       -- sederhana
AddLabel("teks", true, "IdxOpsional")  -- (text, doesWrap, idx)
AddLabel("Idx", { Text="..", DoesWrap=true, Size=14, Visible=true })
AddLabel({ Text="..", DoesWrap=true })
```
Method: `:SetText(str)`, `:SetVisible(bool)`. Tersimpan di `Library.Labels[Idx]`.
Label non-wrap bisa `:AddColorPicker` / `:AddKeyPicker`.

### 6.3 Button — `Groupbox:AddButton(...)` (baris 2144)
```lua
AddButton("Teks", function() end)
AddButton({ Text, Func, DoubleClick, Tooltip, DisabledTooltip, Risky, Disabled, Visible })
AddButton("Idx", { ... })               -- Idx -> Library.Buttons[Idx]
btn:AddButton({ ... })                  -- SubButton (tombol kedua sebaris; hanya satu level)
```
Method: `:SetText`, `:SetDisabled`, `:SetVisible`, `:UpdateColors`. `DoubleClick=true` → perlu klik dua kali (konfirmasi). Ada animasi hover & mode `Risky` (merah).

### 6.4 Toggle & Checkbox — `AddToggle(Idx, Info)` / `AddCheckbox(Idx, Info)` (2637 / 2441)
`Info`: `Text`, `Default`(false), `Callback`, `Changed`, `Risky`, `Disabled`, `Visible`, `Tooltip`, `DisabledTooltip`.
Objek: `.Value` (bool), `.Addons`, `.TextLabel`, `.Holder`. Method: `:SetValue`, `:OnChanged(fn)`, `:SetDisabled`, `:SetVisible`, `:SetText`, `:Display`, `:UpdateColors`.
Disimpan di **`Library.Toggles[Idx]`**. Addon: `:AddColorPicker`, `:AddKeyPicker`.
`SetValue` **diabaikan saat `Disabled`**.

### 6.5 Input — `AddInput(Idx, Info)` (2856)
`Info`: `Text`, `Default`(""), `Finished`(false: nilai diperbarui tiap teks berubah; true: hanya saat menekan Enter, lihat baris 2986), `Numeric`, `ClearTextOnFocus`(true), `Placeholder`, `AllowEmpty`(true), `EmptyReset`("---"), `MaxLength`, `Callback`, `Changed`, `Disabled`, `Visible`, `Tooltip`, `DisabledTooltip`.
Method: `:SetValue(text)`, `:OnChanged`, `:SetDisabled`, `:SetVisible`, `:SetText`. `.Value` = string. → `Library.Options[Idx]`.

### 6.6 Slider — `AddSlider(Idx, Info)` (3015)
`Info`: `Text`, `Default`, `Min`(0), `Max`(100), `Rounding`(0 = bilangan bulat), `Prefix`, `Suffix`, `Compact`, `HideMax`, `Callback`, `Changed`, `Disabled`, `Visible`, `Tooltip`, `DisabledTooltip`.
Method: `:SetValue`, `:SetMin`, `:SetMax`, `:SetPrefix`, `:SetSuffix`, `:SetText`, `:OnChanged`, `:SetDisabled`, `:SetVisible`. `.Value` = number.

### 6.7 Dropdown — `AddDropdown(Idx, Info)` (3269)
`Info`: `Text`, `Values`, `Default` (nama nilai, index angka, atau tabel untuk `Multi`), `Multi`, `AllowNull`, `Searchable`, `DisabledValues`, `MaxVisibleDropdownItems`(8), `FormatDisplayValue(fn)`, `SpecialType` (`"Player"` / `"Team"`), `ExcludeLocalPlayer`, `Callback`, `Changed`, `Disabled`, `Visible`, `Tooltip`, `DisabledTooltip`.
- **`.Value`**: string/nil untuk single; **tabel `{[nilai]=true}`** untuk `Multi`.
- Method: `:SetValue`, `:SetValues(list)`, `:AddValues(list)`, `:SetDisabledValues(list)`, `:AddDisabledValues(list)`, `:GetActiveValues()`, `:BuildDropdownList()`, `:RecalculateListSize(n)`, `:Display()`, `:OnChanged`, `:SetDisabled`, `:SetVisible`, `:SetText`.
- `SpecialType` Player/Team otomatis diperbarui lewat `OnPlayerChange` / `OnTeamChange` (baris 5252–5270).
- Teks tampilan dipotong 25 karakter (`...`).

### 6.8 ColorPicker (addon) — `:AddColorPicker(Idx, Info)` (1607)
`Info`: `Default` (Color3), `Title`, `Transparency` (nilai truthy mengaktifkan slider transparansi; angkanya jadi transparansi awal, 0–1), `Callback`, `Changed`.
Objek: `.Value` (Color3), `.Transparency`, `.Hue/.Sat/.Vib`, `.ColorMenu`, `.ContextMenu` (klik kanan: Copy color, Paste color, Copy Hex, Copy RGB).
Method: `:SetValue({h,s,v}, transparency)`, `:SetValueRGB(Color3, transparency)`, `:Display()`, `:Update()`, `:OnChanged`.
> **Penting:** `SetValue`/`SetValueRGB` hanya memanggil `Display()` — **callback TIDAK dipicu**. Hanya `:Update()` (dipanggil saat user menyeret) yang memicu `Callback`/`Changed`. Efeknya, memuat config via `SaveManager` tidak memicu callback ColorPicker.

### 6.9 KeyPicker (addon) — `:AddKeyPicker(Idx, Info)` (1238)
`Info`: `Text`, `Default` (nama `Enum.KeyCode`, `"MB1"`, `"MB2"`, atau `"None"`), `Mode` (`"Always"|"Toggle"|"Hold"`), `Modes`, `SyncToggleState` (sinkron ke Toggle induk; memaksa `Modes={"Toggle"}`), `NoUI` (jangan tampil di panel keybind), `Callback`, `ChangedCallback`, `Changed`, `Clicked`.
Objek: `.Value` (string key), `.Mode`, `.Toggled`.
Method: `:GetState()` (**cara resmi membaca status aktif**), `:SetValue({key, mode})`, `:SetText`, `:OnChanged`, `:OnClick`, `:DoClick`, `:Display`, `:Update`.
Mendaftar otomatis ke panel keybind (`Library.KeybindToggles`).

### 6.10 Divider — `AddDivider()` (2011)
Garis pemisah; `Type = "Divider"` (disembunyikan oleh Search).

---

## 7. Alur Penting (cara kerja di balik layar)

**Klik Toggle:** `Button.MouseButton1Click` → `Toggle:SetValue(not Value)` → `Display()` (tween + update Registry) → sinkron addon KeyPicker → `SafeCallback(Callback)` → `SafeCallback(Changed)`.

**Ganti tema:** ubah `Library.Scheme.X` → `Library:UpdateColorsUsingRegistry()` → setiap Instance di `Registry` di-set ulang dari Scheme/fungsi.

**Ganti DPI:** `SetDPIScale(%)` → loop `DPIRegistry` (set ulang Size/Position/TextSize/Padding) → `Tab:Resize(true)`, `Groupbox:Resize()`, `SubTab:Resize()` → `Dropdown:RecalculateListSize`, `KeyPicker:Update` → resize notifikasi.

**Search (kotak pencarian window):** `SearchBox:GetPropertyChangedSignal("Text")` (baris 5076). Mereset visibilitas tab terakhir, lalu untuk tab aktif menyembunyikan semua elemen yang `Text`-nya tidak cocok (`string.match` huruf kecil — **pola Lua, bukan teks literal**). Elemen tanpa field `Text` dan `Divider` disembunyikan. Groupbox/Tabbox tanpa hasil disembunyikan.
→ **Elemen baru harus punya `.Text`, `.Visible`, `.Holder`, dan masuk `Groupbox.Elements`** agar kompatibel dengan Search.

**Popup (Dropdown/KeyPicker/ColorPicker):** semua lewat `Library:AddContextMenu`. Menutup otomatis saat klik di luar & saat window ditutup (`Library:Toggle`).

**Unload:** `Library:Unload()` — jika Anda menambah koneksi global, bungkus dengan `Library:GiveSignal(...)`; jika menambah state, daftarkan `Library:OnUnload`.

---

## 8. Alur Pemakaian Standar (dari `Example.lua`)

```lua
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library      = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({ Title = "My Script", Footer = "v1", ToggleKeybind = Enum.KeyCode.RightControl })
local Tabs = {
    Main = Window:AddTab("Main", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

local G = Tabs.Main:AddLeftGroupbox("Groupbox")
G:AddToggle("MyToggle", { Text = "Toggle", Default = false, Callback = function(v) end })
  :AddColorPicker("MyColor", { Default = Color3.new(1,0,0) })
  :AddKeyPicker("MyKey", { Default = "E", Mode = "Toggle", Text = "Bind", SyncToggleState = true })

-- Baca nilai kapan pun:
Library.Toggles.MyToggle.Value
Library.Options.MyColor.Value
Library.Options.MyKey:GetState()

-- Addon:
ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })
ThemeManager:SetFolder("MyHub"); SaveManager:SetFolder("MyHub/game")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])
SaveManager:LoadAutoloadConfig()
```

> URL `repo` di atas mengikuti README. Ubah jika Anda memakai fork sendiri.

---

## 9. Addon: `SaveManager` (`addons/SaveManager.lua`)

- **Fungsi:** menyimpan semua `Library.Toggles` + `Library.Options` ke file JSON (`<Folder>/settings/<nama>.json`, atau `<Folder>/settings/<SubFolder>/<nama>.json` jika `SetSubFolder` dipakai; tema kustom di `<Folder>/themes`) memakai API file executor (`writefile`, `readfile`, `isfolder`, …).
- **Parser** (baris 40–105) → tabel per `Type`: `Toggle`, `Slider`, `Dropdown`, `ColorPicker`, `KeyPicker`, `Input`. Setiap entri punya `Save(idx, obj)` dan `Load(idx, data)`.
  **Tipe elemen baru tidak akan tersimpan kecuali Anda menambahkan entri di `SaveManager.Parser`.**
- Method utama: `SetLibrary`, `SetFolder`, `SetSubFolder`, `SetIgnoreIndexes(list)`, `IgnoreThemeSettings()` (mengabaikan `BackgroundColor, MainColor, AccentColor, OutlineColor, FontColor, FontFace, ThemeManager_*`), `Save(name)`, `Load(name)`, `Delete(name)`, `RefreshConfigList()`, `GetAutoloadConfig()`, `LoadAutoloadConfig()`, `SaveAutoloadConfig(name)`, `DeleteAutoLoadConfig()`, `BuildConfigSection(tab)` (UI: nama config, daftar, Create/Load/Overwrite/Refresh/Set autoload).
- Load memakai `task.spawn` agar satu config rusak tidak macet.
- Elemen dengan `Idx` yang ada di `Ignore` dilewati saat Save.

## 10. Addon: `ThemeManager` (`addons/ThemeManager.lua`)

- **`BuiltInThemes`** (baris 42–61): 18 tema — Default, BBot, Fatality, Jester, Mint, Tokyo Night, Ubuntu, Quartz, Nord, Dracula, Monokai, Gruvbox, Solarized, Catppuccin, One Dark, Cyberpunk, Oceanic Next, Material.
  Format: `["Nama"] = { urutan, { FontColor, MainColor, AccentColor, BackgroundColor, OutlineColor } }` (hex tanpa `#`). **Untuk menambah tema, tambahkan satu baris di sini** (beri nomor urutan unik — dipakai `table.sort`).
- Method: `SetLibrary`, `SetFolder`, `ApplyTheme(name)`, `ThemeUpdate()`, `GetCustomTheme(file)`, `LoadDefault()`, `SaveDefault(theme)`, `SaveCustomTheme(file)`, `Delete(name)`, `ReloadCustomThemes()`, `CreateThemeManager(groupbox)` (UI: 5 ColorPicker `FontColor/MainColor/AccentColor/BackgroundColor/OutlineColor` + dropdown tema + dropdown font `FontFace` + simpan tema kustom), `CreateGroupBox(tab)`, `ApplyToTab(tab)`, `ApplyToGroupbox(groupbox)`.
- Alur `ApplyTheme`: set `Library.Scheme[key] = Color3.fromHex(...)` → sinkron ColorPicker terkait via `SetValueRGB` → `ThemeUpdate()` → `Library:UpdateColorsUsingRegistry()`.
- Index (`Idx`) yang dipakai: `FontColor, MainColor, AccentColor, BackgroundColor, OutlineColor, FontFace, ThemeManager_ThemeList, ThemeManager_CustomThemeList`, dst. Hindari memakai Idx yang sama di script Anda.

---

## 11. Resep Modifikasi

### 11.1 Mengubah nilai default / perilaku global
Edit `Templates.<Elemen>` (baris 107–253) atau field awal di tabel `Library` (baris 35–90).

### 11.2 Menambah opsi baru pada elemen yang sudah ada (mis. `Slider.Step`)
1. Tambahkan default di `Templates.Slider`.
2. Baca `Info.Step` di dalam `Funcs:AddSlider` (baris 3015–3268) dan terapkan pada logika `SetValue` / drag.
3. Jika perlu diekspos: simpan ke objek (`Slider.Step = Info.Step`).
4. Jika perlu tersimpan: perbarui `SaveManager.Parser.Slider`.
5. Dokumentasikan di README.

### 11.3 Menambah jenis elemen baru (mis. `AddProgressBar`)
1. Tambahkan `Templates.ProgressBar` (opsional tapi disarankan).
2. Dalam blok **BaseGroupbox**, tulis `function Funcs:AddProgressBar(Idx, Info)` mengikuti pola §2.3. Gunakan `New(...)` dengan **string key Scheme** untuk warna dan ukuran dalam pixel (otomatis ter-DPI).
3. Pastikan: `Type`, `Holder`, `Text`, `Visible`, `table.insert(Groupbox.Elements, obj)`, `Groupbox:Resize()`, dan didaftarkan ke `Options[Idx]` / `Toggles[Idx]`.
4. Sediakan `:SetVisible` (panggil `Groupbox:Resize()` di dalamnya) dan `:SetDisabled` jika relevan.
5. Tambahkan `Parser` di SaveManager bila nilainya perlu persist.
6. Pakai `Library:SafeCallback` untuk semua callback.

### 11.4 Menambah addon yang menempel pada Label/Toggle
Tambahkan `function Funcs:AddXxx(Idx, Info)` di blok **BaseAddons**. Gunakan `self.TextLabel` sebagai parent UI (lihat `AddColorPicker`, baris 1607–1640), `table.insert(self.Addons, obj)` jika perlu, simpan ke `Options[Idx]`, dan `return self` agar bisa dirantai.

### 11.5 Menambah field warna tema baru (mis. `SuccessColor`)
1. Tambahkan ke `Library.Scheme` (baris 75–85).
2. Pakai string `"SuccessColor"` pada properti warna di `New(...)`.
3. ThemeManager: tambahkan ke array `options` di `ThemeUpdate`, ke setiap `BuiltInThemes`, ke `CreateThemeManager` (ColorPicker baru), dan ke daftar `IgnoreThemeSettings` di SaveManager.

### 11.6 Menambah tema bawaan
Tambah baris di `ThemeManager.BuiltInThemes` (lihat §10).

### 11.7 Mengubah tampilan window (ukuran/tinggi header/sidebar)
Semua ada di `CreateWindow` (baris 3950–4234). Pencarian cepat: cari komentar `--// Execution \\--` dan nama variabel `MainFrame`, `Tabs`, `Container`, `SearchBox`, `ResizeButton`.

### 11.8 Debugging cepat
- Callback error disembunyikan oleh `SafeCallback` → set `Library.NotifyOnError = true` untuk melihatnya di UI.
- Elemen tidak ikut tema → cek apakah warnanya string key Scheme / ada di `Library.Registry[inst]`.
- Ukuran salah di DPI ≠ 100% → cek apakah `Size/Position` diset manual tanpa `Library:UpdateDPI`.
- Elemen tidak tersaring oleh Search → cek `Elements`, `.Text`, `.Holder`.

---

## 12. Gotcha / Bug / Keanehan yang Terverifikasi di Kode

Ini temuan dari pembacaan kode (bukan asumsi). Hati-hati sebelum "memperbaikinya" — tentukan dulu apakah perilaku ini diandalkan.

1. **`Visible` pada Label & Button selalu `true` saat memakai tabel.**
   `Data.Visible = Params.Visible or true` (Label, baris 2043) dan `Info.Visible = Params.Visible or true` (Button, baris 2163). `false or true` → `true`, sehingga `Visible = false` pada konstruktor **tidak berfungsi**. Perbaikan: `if Params.Visible == nil then true else Params.Visible`. Sementara itu, gunakan `:SetVisible(false)` setelah dibuat.
2. **`ColorPicker:SetValue/SetValueRGB` tidak memicu callback** (lihat §6.8). Hanya `Display()`.
3. **Typo di SaveManager:** Dropdown menyimpan field `mutli = object.Multi` (baris 65). Konsisten saat dibaca, tapi bila diperbaiki ke `multi` config lama tidak akan terbaca.
4. **`SetDPIScale` bersifat kumulatif pada `MinSize`:** `Library.MinSize *= Library.DPIScale` (baris ≈ 405). Memanggil berkali-kali (mis. 125 → 100 → 125) mengalikan `MinSize` berulang, bukan dihitung ulang dari nilai dasar.
5. **`Idx` duplikat menimpa elemen** di `Options`/`Toggles` tanpa error.
6. **Key `Library.Tabs[Name]` dan `Tab.Groupboxes[Name]`** memakai nama sebagai kunci → nama kembar menimpa. Tabbox tanpa nama memakai `table.insert`.
7. **Search memakai `string.match`:** karakter pola seperti `(`, `%`, `[` dalam teks pencarian bisa menyebabkan error/hasil salah.
8. **Tab biasa bukan Groupbox sungguhan** (§2.4): tab non-key tidak punya `Elements`, jadi `Tab:AddToggle` langsung tidak didukung.
9. **Label `DoesWrap = true` tidak mendukung addon** (tidak diberi `BaseAddons`).
10. **Ikon Lucide diambil dari jaringan** saat load; gagal → `nil`, UI tetap jalan tanpa ikon. Ikon yang dicache (`CheckIcon`, `ArrowIcon`, …) dipakai langsung (cek `nil` dulu bila Anda menambah pemakaian baru).
11. **`Library` bersifat singleton:** `ScreenGui` dibuat saat file dimuat, dan `getgenv().Library` ditimpa. Memuat dua kali tanpa `Unload` meninggalkan GUI ganda.
12. **Shim executor:** `cloneref`, `gethui`, `protectgui`, `getgenv` punya fallback; di Roblox Studio murni `HttpGet`/`loadstring`/`writefile` tidak tersedia kecuali diaktifkan/di-mock.
13. **README vs kode:** README adalah dokumentasi tulisan tangan dan bisa tertinggal; CHANGELOG tidak dirawat.

---

## 13. Konvensi Kode yang Dipakai

- Indentasi 4 spasi (Library & SaveManager sebagian pakai tab di `Example.lua`/`ThemeManager.lua`; ikuti gaya file yang diedit).
- Nama method publik **PascalCase** (`SetValue`, `AddToggle`); variabel lokal **PascalCase** di `Library.lua`.
- Komentar section: `--// Nama \\--`.
- Anotasi tipe Luau opsional di parameter (`Text: string`, `Visible: boolean`).
- Ukuran UI dalam pixel dasar 100% (DPI ditangani otomatis oleh `New`).
- Gunakan `continue` (Luau) dan `+=` — **kode ini tidak kompatibel dengan Lua 5.1 murni**.

---

## 14. Lampiran — Indeks Fungsi Otomatis (nomor baris)

Dihasilkan dengan skrip dari file di repo. Fungsi bersarang (indent dalam) ikut tercantum; urutan sama dengan di file.

### `Library.lua`

| Baris | Fungsi |
|---|---|
| 257 | `ApplyDPIScale(Dimension, ExtraOffset)` |
| 278 | `ApplyTextScale(TextSize)` |
| 281 | `WaitForEvent(Event, Timeout, Condition)` |
| 296 | `IsClickInput(Input: InputObject, IncludeM2: boolean?)` |
| 303 | `IsHoverInput(Input: InputObject)` |
| 307 | `GetTableSize(Table: { [any]: any })` |
| 316 | `StopTween(Tween: TweenBase)` |
| 323 | `Trim(Text: string)` |
| 327 | `GetPlayers(ExcludeLocalPlayer: boolean?)` |
| 343 | `GetTeams()` |
| 353 | `Library:UpdateKeybindFrame()` |
| 373 | `Library:AddToRegistry(Instance, Properties)` |
| 377 | `Library:RemoveFromRegistry(Instance)` |
| 381 | `Library:UpdateColorsUsingRegistry()` |
| 393 | `Library:UpdateDPI(Instance, Properties)` |
| 403 | `Library:SetDPIScale(DPIScale: number)` |
| 449 | `Library:GiveSignal(Connection: RBXScriptConnection)` |
| 459 | `Library:GetIcon(IconName: string)` |
| 470 | `Library:Validate(Table: { [string]: any }, Template: { [string]: any })` |
| 487 | `FillInstance(Table: { [string]: any }, Instance: GuiObject)` |
| 528 | `New(ClassName: string, Properties: { [string]: any })` |
| 546 | `ParentUI(UI: Instance)` |
| 633 | `Library:GetBetterColor(Color: Color3, Add: number)` |
| 642 | `Library:GetDarkerColor(Color: Color3)` |
| 647 | `Library:GetKeyString(KeyCode: Enum.KeyCode)` |
| 655 | `Library:GetTextBounds(Text: string, Font: Font, Size: number, Width: number?)` |
| 667 | `Library:MouseIsOverFrame(Frame: GuiObject, Mouse: Vector2)` |
| 675 | `Library:SafeCallback(Func: (...any)` |
| 695 | `Library:MakeDraggable(UI: GuiObject, DragFrame: GuiObject, IgnoreToggled: boolean?, IsMainWindow: boolean?)` |
| 744 | `Library:MakeResizable(UI: GuiObject, DragFrame: GuiObject, Callback: ()` |
| 796 | `Library:MakeCover(Holder: GuiObject, Place: string)` |
| 811 | `Library:MakeLine(Frame: GuiObject, Info)` |
| 823 | `Library:MakeOutline(Frame: GuiObject, Corner: number?, ZIndex: number?)` |
| 854 | `Library:AddDraggableButton(Text: string, Func)` |
| 880 | `Table:SetText(NewText: string)` |
| 894 | `Library:AddDraggableMenu(Name: string)` |
| 1018 | `Table:Open()` |
| 1065 | `Table:Close()` |
| 1082 | `Table:Toggle()` |
| 1090 | `Table:SetSize(Size)` |
| 1143 | `Library:AddTooltip(InfoStr: string, DisabledInfoStr: string, HoverInstance: GuiObject)` |
| 1150 | `DoHover()` |
| 1195 | `TooltipTable:Destroy()` |
| 1210 | `Library:OnUnload(Callback)` |
| 1214 | `Library:Unload()` |
| 1238 | `Funcs:AddKeyPicker(Idx, Info)` |
| 1325 | `KeybindsToggle:Display(State)` |
| 1330 | `KeybindsToggle:SetText(Text)` |
| 1336 | `KeybindsToggle:SetVisibility(Visibility)` |
| 1340 | `KeybindsToggle:SetNormal(Normal)` |
| 1383 | `ModeButton:Select()` |
| 1396 | `ModeButton:Deselect()` |
| 1414 | `KeyPicker:Display()` |
| 1425 | `KeyPicker:Update()` |
| 1455 | `KeyPicker:GetState()` |
| 1476 | `KeyPicker:OnChanged(Func)` |
| 1480 | `KeyPicker:OnClick(Func)` |
| 1484 | `KeyPicker:DoClick()` |
| 1493 | `KeyPicker:SetValue(Data)` |
| 1504 | `KeyPicker:SetText(Text)` |
| 1607 | `Funcs:AddColorPicker(Idx, Info)` |
| 1805 | `CreateButton(Text, Func)` |
| 1844 | `ColorPicker:SetHSVFromRGB(Color)` |
| 1848 | `ColorPicker:Display()` |
| 1878 | `ColorPicker:Update()` |
| 1885 | `ColorPicker:OnChanged(Func)` |
| 1889 | `ColorPicker:SetValue(HSV, Transparency)` |
| 1897 | `ColorPicker:SetValueRGB(Color, Transparency)` |
| 2011 | `Funcs:AddDivider()` |
| 2031 | `Funcs:AddLabel(...)` |
| 2074 | `Label:SetVisible(Visible: boolean)` |
| 2081 | `Label:SetText(Text: string)` |
| 2144 | `Funcs:AddButton(...)` |
| 2145 | `GetInfo(...)` |
| 2216 | `CreateButton(Button)` |
| 2237 | `InitEvents(Button)` |
| 2293 | `Button:AddButton(...)` |
| 2317 | `SubButton:UpdateColors()` |
| 2333 | `SubButton:SetDisabled(Disabled: boolean)` |
| 2344 | `SubButton:SetVisible(Visible: boolean)` |
| 2351 | `SubButton:SetText(Text: string)` |
| 2378 | `Button:UpdateColors()` |
| 2393 | `Button:SetDisabled(Disabled: boolean)` |
| 2404 | `Button:SetVisible(Visible: boolean)` |
| 2411 | `Button:SetText(Text: string)` |
| 2441 | `Funcs:AddCheckbox(Idx, Info)` |
| 2520 | `Toggle:UpdateColors()` |
| 2524 | `Toggle:Display()` |
| 2552 | `Toggle:OnChanged(Func)` |
| 2556 | `Toggle:SetValue(Value)` |
| 2575 | `Toggle:SetDisabled(Disabled: boolean)` |
| 2592 | `Toggle:SetVisible(Visible: boolean)` |
| 2599 | `Toggle:SetText(Text: string)` |
| 2637 | `Funcs:AddToggle(Idx, Info)` |
| 2726 | `Toggle:UpdateColors()` |
| 2730 | `Toggle:Display()` |
| 2771 | `Toggle:OnChanged(Func)` |
| 2775 | `Toggle:SetValue(Value)` |
| 2794 | `Toggle:SetDisabled(Disabled: boolean)` |
| 2811 | `Toggle:SetVisible(Visible: boolean)` |
| 2818 | `Toggle:SetText(Text: string)` |
| 2856 | `Funcs:AddInput(Idx, Info)` |
| 2925 | `Input:UpdateColors()` |
| 2934 | `Input:OnChanged(Func)` |
| 2938 | `Input:SetValue(Text)` |
| 2962 | `Input:SetDisabled(Disabled: boolean)` |
| 2974 | `Input:SetVisible(Visible: boolean)` |
| 2981 | `Input:SetText(Text: string)` |
| 3015 | `Funcs:AddSlider(Idx, Info)` |
| 3099 | `Slider:UpdateColors()` |
| 3113 | `Slider:Display()` |
| 3138 | `Slider:OnChanged(Func)` |
| 3142 | `Round(Value)` |
| 3150 | `Slider:SetMax(Value)` |
| 3158 | `Slider:SetMin(Value)` |
| 3166 | `Slider:SetValue(Str)` |
| 3185 | `Slider:SetDisabled(Disabled: boolean)` |
| 3196 | `Slider:SetVisible(Visible: boolean)` |
| 3203 | `Slider:SetText(Text: string)` |
| 3212 | `Slider:SetPrefix(Prefix: string)` |
| 3217 | `Slider:SetSuffix(Suffix: string)` |
| 3269 | `Funcs:AddDropdown(Idx, Info)` |
| 3396 | `Dropdown:RecalculateListSize(Count)` |
| 3408 | `Dropdown:UpdateColors()` |
| 3418 | `Dropdown:Display()` |
| 3449 | `Dropdown:OnChanged(Func)` |
| 3453 | `Dropdown:GetActiveValues()` |
| 3468 | `Dropdown:BuildDropdownList()` |
| 3511 | `Table:UpdateButton()` |
| 3556 | `Dropdown:SetValue(Value)` |
| 3586 | `Dropdown:SetValues(Values)` |
| 3591 | `Dropdown:AddValues(Values)` |
| 3605 | `Dropdown:SetDisabledValues(DisabledValues)` |
| 3610 | `Dropdown:AddDisabledValues(DisabledValues)` |
| 3624 | `Dropdown:SetDisabled(Disabled: boolean)` |
| 3636 | `Dropdown:SetVisible(Visible: boolean)` |
| 3643 | `Dropdown:SetText(Text: string)` |
| 3718 | `Library:SetFont(FontFace)` |
| 3727 | `Library:SetNotifySide(Side: string)` |
| 3741 | `Library:Notify(...)` |
| 3836 | `Data:Resize()` |
| 3862 | `Data:ChangeTitle(NewText)` |
| 3870 | `Data:ChangeDescription(NewText)` |
| 3878 | `Data:ChangeStep(NewStep)` |
| 3950 | `Library:CreateWindow(WindowInfo)` |
| 4238 | `Window:AddTab(Name: string, Icon)` |
| 4421 | `Tab:UpdateWarningBox(Info)` |
| 4471 | `Tab:Resize(ResizeWarningBox: boolean?)` |
| 4495 | `Tab:AddGroupbox(Info)` |
| 4564 | `Groupbox:Resize()` |
| 4576 | `Tab:AddLeftGroupbox(Name)` |
| 4580 | `Tab:AddRightGroupbox(Name)` |
| 4584 | `Tab:AddTabbox(Info)` |
| 4625 | `Tabbox:AddTab(Name)` |
| 4668 | `Tab:Show()` |
| 4683 | `Tab:Hide()` |
| 4692 | `Tab:Resize()` |
| 4722 | `Tab:AddLeftTabbox(Name)` |
| 4726 | `Tab:AddRightTabbox(Name)` |
| 4730 | `Tab:Hover(Hovering)` |
| 4745 | `Tab:Show()` |
| 4766 | `Tab:Hide()` |
| 4801 | `Window:AddKeyTab(Name)` |
| 4877 | `Tab:AddKeyBox(...)` |
| 4933 | `Tab:Resize()` |
| 4935 | `Tab:Hover(Hovering)` |
| 4950 | `Tab:Show()` |
| 4971 | `Tab:Hide()` |
| 5009 | `Library:Toggle(Value: boolean?)` |
| 5252 | `OnPlayerChange()` |
| 5261 | `OnTeamChange()` |

### `addons/SaveManager.lua`

| Baris | Fungsi |
|---|---|
| 107 | `SaveManager:SetLibrary(library)` |
| 111 | `SaveManager:IgnoreThemeSettings()` |
| 119 | `SaveManager:CheckSubFolder(createFolder)` |
| 131 | `SaveManager:GetPaths()` |
| 156 | `SaveManager:BuildFolderTree()` |
| 167 | `SaveManager:CheckFolderTree()` |
| 174 | `SaveManager:SetIgnoreIndexes(list)` |
| 180 | `SaveManager:SetFolder(folder)` |
| 185 | `SaveManager:SetSubFolder(folder)` |
| 191 | `SaveManager:Save(name)` |
| 231 | `SaveManager:Load(name)` |
| 257 | `SaveManager:Delete(name)` |
| 275 | `SaveManager:RefreshConfigList()` |
| 326 | `SaveManager:GetAutoloadConfig()` |
| 347 | `SaveManager:LoadAutoloadConfig()` |
| 370 | `SaveManager:SaveAutoloadConfig(name)` |
| 384 | `SaveManager:DeleteAutoLoadConfig()` |
| 399 | `SaveManager:BuildConfigSection(tab)` |

### `addons/ThemeManager.lua`

| Baris | Fungsi |
|---|---|
| 63 | `ThemeManager:SetLibrary(library)` |
| 68 | `ThemeManager:GetPaths()` |
| 81 | `ThemeManager:BuildFolderTree()` |
| 91 | `ThemeManager:CheckFolderTree()` |
| 98 | `ThemeManager:SetFolder(folder)` |
| 104 | `ThemeManager:ApplyTheme(theme)` |
| 132 | `ThemeManager:ThemeUpdate()` |
| 144 | `ThemeManager:GetCustomTheme(file)` |
| 160 | `ThemeManager:LoadDefault()` |
| 183 | `ThemeManager:SaveDefault(theme)` |
| 187 | `ThemeManager:SaveCustomTheme(file)` |
| 203 | `ThemeManager:Delete(name)` |
| 217 | `ThemeManager:ReloadCustomThemes()` |
| 245 | `ThemeManager:CreateThemeManager(groupbox)` |
| 337 | `UpdateTheme()` |
| 349 | `ThemeManager:CreateGroupBox(tab)` |
| 354 | `ThemeManager:ApplyToTab(tab)` |
| 360 | `ThemeManager:ApplyToGroupbox(groupbox)` |
