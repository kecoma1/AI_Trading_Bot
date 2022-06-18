from bot import Bot
import MetaTrader5 as mt5


mt5.initialize()

ai_bot = Bot(0.01, 60, "Boom 300 Index")

ai_bot.start()
ai_bot.wait()