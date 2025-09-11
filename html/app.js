let levelsData = [];

function updateLevels(levels) {
    levelsData = Object.values(levels);
    renderLevels();
}

function renderLevels() {
    const levelsGrid = document.getElementById('levels-grid');
    levelsGrid.innerHTML = '';

    levelsData.forEach(level => {
        const levelItem = document.createElement('div');
        levelItem.className = 'level-item';
        
        const progressPercent = level.progress || (level.xp % 100);
        
        levelItem.innerHTML = `
            <div class="level-header">
                <span class="level-name">${level.name}</span>
                <div class="level-info">
                    <span class="level-xp">XP: ${level.xp}</span>
                    <span class="level-value">Level ${level.level}</span>
                </div>
            </div>
            <div class="level-description">${level.description || 'No description available'}</div>
            <div class="level-progress">
                <div class="level-progress-bar" style="width: ${progressPercent}%">
                    <span class="progress-text">${Math.round(progressPercent)}%</span>
                </div>
            </div>
        `;
        levelsGrid.appendChild(levelItem);
    });
}

function toggleUI(show) {
    const body = document.body;
    const tabletFrame = document.getElementById('tablet-frame');
    
    if (show) {
        body.classList.add('active');
        tabletFrame.style.display = 'flex';
        // Small delay to ensure smooth transition
        setTimeout(() => {
            tabletFrame.style.opacity = '1';
        }, 10);
    } else {
        tabletFrame.style.opacity = '0';
        setTimeout(() => {
            body.classList.remove('active');
            tabletFrame.style.display = 'none';
        }, 300);
    }
}

function closeUI() {
    toggleUI(false);
    fetch('https://sd-levels/closeUI', {method: 'POST'});
}

// Event Listeners
window.addEventListener('message', (event) => {
    if (event.data.action === 'updateLevels') {
        updateLevels(event.data.levels);
    } else if (event.data.action === 'toggleUI') {
        toggleUI(event.data.show);
    }
});

document.getElementById('close-button').addEventListener('click', closeUI);

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' || event.key === 'Backspace') {
        event.preventDefault();
        closeUI();
    }
});

// Initialize with empty levels if needed
renderLevels();